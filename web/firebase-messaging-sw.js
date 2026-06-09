importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCUnd6biBQQtGg7QSTMfPMCCjPI52k677g",
  authDomain: "aegis-7b556.firebaseapp.com",
  projectId: "aegis-7b556",
  storageBucket: "aegis-7b556.firebasestorage.app",
  messagingSenderId: "1070574255763",
  appId: "1:1070574255763:android:43a209eaa4e81973235766"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/favicon.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
