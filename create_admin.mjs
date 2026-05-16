import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc } from 'firebase/firestore';
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'AIzaSyA-kgFaCuV_-bocHxtRQ_HwOiashSk2qE0',
  authDomain: 'jewelry-ai-app-bba3d.firebaseapp.com',
  projectId: 'jewelry-ai-app-bba3d',
  storageBucket: 'jewelry-ai-app-bba3d.firebasestorage.app',
  messagingSenderId: '79453872525',
  appId: '1:79453872525:web:48351645a932695f151dc4'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

async function createAdmin() {
  const email = 'huyadmin@gmail.com';
  const password = '123456';

  let user;
  try {
    console.log('Attempting to create user...');
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    user = userCredential.user;
    console.log('Created user with UID:', user.uid);
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      console.log('User already exists, signing in...');
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      user = userCredential.user;
      console.log('Signed in with UID:', user.uid);
    } else {
      console.error('Error with auth:', error);
      process.exit(1);
    }
  }

  try {
    console.log('Adding to admins collection...');
    await setDoc(doc(db, 'admins', user.uid), {
      email: email,
      createdAt: new Date(),
      role: 'superadmin'
    });
    console.log('Successfully added to admins collection!');
    process.exit(0);
  } catch (error) {
    console.error('Error adding to admins collection:', error);
    process.exit(1);
  }
}

createAdmin();
