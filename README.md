![PetTrack Banner](./assets/images/logo.png)

# 🐾 PetTrack: Gestió intel·ligent de mascotes

**PetTrack** és una aplicació dissenyada per simplificar i centralitzar la gestió del benestar de les teves mascotes. Amb PetTrack, tindràs tota la informació essencial en un sol lloc, de manera clara i intuïtiva, permetent-te concentrar-te en la cura del teu animal sense preocupar-te per recordar cada detall.

Aquest projecte ha estat desenvolupat com a part del repte **"Hackathons of Cloud Services: Co-creating and deploying"** dins l’assignatura de **Sistemes Multimèdia 2024–2025**.

## 👨‍💻 Desenvolupada per:

* **Albert Capdevila Estadella** (1587933)
* **Levon Kesoyan Galstyan** (1668018)
* **Luis Martínez Zamora** (1668180)

## 📱 Funcionalitats Clau

PetTrack és una aplicació mòbil robusta que permet als usuaris registrar-se amb el seu compte de Google i gestionar de manera eficient diversos aspectes de la vida de les seves mascotes. Les seves funcionalitats principals inclouen:

* **Enregistrament Complet de Mascotes**: Registra cada una de les teves mascotes amb detalls com nom, imatge, data de naixement i altres dades rellevants. La raça de l'animal es detecta automàticament mitjançant intel·ligència artificial, i tota la informació es desa al núvol per a un accés constant.
* **Calendari i Recordatoris Intel·ligents**: Afegeix esdeveniments importants per a cada mascota, com visites al veterinari, medicacions o sessions d'higiene. Aquests esdeveniments se sincronitzen automàticament amb un nou calendari específic que es crea a Google Calendar.
* **Registre de Rutes de Passeig**: Enregistra els recorreguts de passeig i associa'ls a una o més mascotes. Aquesta funcionalitat aprofita el GPS del teu dispositiu i s'integra amb Google Maps per oferir mapes actualitzats i fiables.
* **Informació Personalitzada amb IA**: Utilitzem la Gemini API per oferir informació rellevant i personalitzada sobre la teva mascota a partir dels seus atributs registrats. És una manera pràctica d'entendre millor les necessitats del teu animal.
* **Gestió Detallada de la Dieta**: Defineix la freqüència dels àpats per a cada mascota. L'aplicació inclou un comptador diari fàcil d'usar per registrar cada menjada. Al final del dia, el comptador es reinicia automàticament, i si una mascota no ha rebut el nombre d'àpats establert, rebràs una notificació.

## ☁️ Tecnologies i Arquitectura

PetTrack s'ha desenvolupat amb **Flutter**, un framework de Google que permet la construcció d'aplicacions mòbils natives amb widgets programats en Dart. L'arquitectura es basa en un model client-servidor modern, interactuant amb diversos serveis de Google Cloud mitjançant APIs i funcions al núvol.

Les tecnologies utilitzades inclouen:

### Google Cloud Platform
* 🔐 **Firebase Authentication**: Gestió d'autenticació d'usuaris, permetent l'inici de sessió amb el compte de Google i assegurant l'accés segur a les dades de cada usuari mitjançant regles de Firebase.
* 🔥 **Cloud Firestore**: Base de dades NoSQL principal per emmagatzemar tota la informació del sistema: mascotes registrades, àpats, dades d'usuari i rutes realitzades.
* 📦 **Firebase Storage**: Utilitzat per emmagatzemar les imatges de les mascotes al núvol.
* 📆 **Google Calendar API**: Integració per crear automàticament un calendari específic per a l'usuari a Google Calendar i afegir-hi esdeveniments.
* 🗺️ **Google Maps API**: Visualització de mapes dins de l'aplicació i registre de rutes de passeig, associant-les a una o més mascotes.
* 🧠 **Gemini API**: Integració d'intel·ligència artificial generativa per identificar la raça de l'animal a partir d'una imatge i generar informació útil i recomanacions personalitzades.
* ☁️ **Cloud Functions**: Conté la lògica del backend escalable que s'executa automàticament o en resposta a esdeveniments, com el reinici diari del comptador d'àpats i l'enviament de notificacions.
* 🔔 **Firebase Messaging**: Serveix per enviar notificacions als usuaris, com avisos sobre àpats incomplets.
* ⏰ **Cloud Scheduler**: Programa tasques automàtiques com l'activació diària de Cloud Functions.
* 🔄 **Pub/Sub (Publisher/Subscriber)**: Facilita la comunicació deslligada i coordinada entre serveis, com entre Cloud Scheduler i Cloud Functions.

## 🚀 Com començar

Per començar amb PetTrack, segueix els passos següents:

1.  Clona el repositori:
    ```bash
    git clone [https://github.com/nom-del-teu-usuari/PetTrack.git](https://github.com/nom-del-teu-usuari/PetTrack.git)
    cd PetTrack
    ```
