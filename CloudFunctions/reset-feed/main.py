import logging
import firebase_admin
from firebase_admin import messaging
from google.cloud import firestore
import functions_framework
from cloudevents.http import CloudEvent
import logging

# Aquesta Cloud Function reinicia el comptador de racions diàries de les mascotes
# En cas de no haber arribat al número de racions diàries establert, envia una notificació a l'usuari.
# S'invoca cada dia a las 00:00, mitjançant una cadena: Cloud Scheduler -> Pub/Sub -> Cloud Function
# Per tant, no la invoquem nosaltres directament, sinó que la Cloud Function s'executa automàticament.
logging.basicConfig(level=logging.INFO)

firebase_admin.initialize_app()
db = firestore.Client()

@functions_framework.cloud_event
def reset_daily_feed_count(event: CloudEvent):
    pets = db.collection_group("pets").stream()
    batch = db.batch()
    notif_queue = []
    total_pets = 0
    for pet_doc in pets:
        total_pets +=1
        pet = pet_doc.to_dict()
        count = pet.get("dailyFeedCount", 0)
        goal  = pet.get("dailyFeedGoal", 0)

        user_ref = pet_doc.reference.parent.parent
        user_snap = user_ref.get()
        token = user_snap.get("fcmToken") if user_snap.exists else None

        if count < goal and token:
            notif_queue.append(
                messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title=f"⚠️ {pet.get('name','Mascota')} s'ha quedat amb gana!",
                        body=f"Només ha menjat {count} de {goal} racions avui",
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
            resp = messaging.send(msg)
            logging.info("✓ Notificación enviada a %s : %s", msg.token, resp)
        except Exception as e:
            logging.exception("Error enviando notificación FCM: %s", e)
    logging.info("Total mascotas evaluadas: %s", total_pets)
    logging.info("Notificaciones a enviar: %s", len(notif_queue))
