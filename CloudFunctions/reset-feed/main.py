import logging

import firebase_admin
import functions_framework
from cloudevents.http import CloudEvent
from firebase_admin import messaging
from google.cloud import firestore

logging.basicConfig(level=logging.INFO)

firebase_admin.initialize_app()
db = firestore.Client()


@functions_framework.cloud_event
def reset_daily_feed_count(event: CloudEvent):
    """Reset feeding counts and notify owners whose pets missed their daily goal.

    The historical deployment used Scheduler -> Pub/Sub at midnight. Its schedule
    is external to this repository. All pet updates share one Firestore batch;
    this implementation assumes the collection fits within the service limits.
    """
    pets = db.collection_group("pets").stream()
    batch = db.batch()
    notif_queue = []
    total_pets = 0
    for pet_doc in pets:
        total_pets += 1
        pet = pet_doc.to_dict()
        count = pet.get("dailyFeedCount", 0)
        goal = pet.get("dailyFeedGoal", 0)

        user_ref = pet_doc.reference.parent.parent
        user_snap = user_ref.get()
        token = user_snap.get("fcmToken") if user_snap.exists else None

        if count < goal and token:
            notif_queue.append(
                messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title=f"⚠️ {pet.get('name', 'Pet')} missed their feeding goal!",
                        body=f"Only {count} of {goal} meals recorded today",
                    ),
                    data={"petId": pet_doc.id},
                )
            )

        batch.update(
            pet_doc.reference,
            {"dailyFeedCount": 0, "lastReset": firestore.SERVER_TIMESTAMP},
        )

    batch.commit()

    for msg in notif_queue:
        try:
            messaging.send(msg)
            logging.info("Feeding reminder sent.")
        except Exception as error:
            # Provider exception text can include recipient or request details.
            logging.error("FCM notification failed (%s).", type(error).__name__)
    logging.info("Total pets evaluated: %s", total_pets)
    logging.info("Notifications queued: %s", len(notif_queue))
