const admin = require('firebase-admin');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!serviceAccountPath) {
  console.error('Error: GOOGLE_APPLICATION_CREDENTIALS environment variable not set.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath))
});

const db = admin.firestore();

async function updateVersion() {
  const args = process.argv.slice(2);
  if (args.length < 3) {
    console.error('Usage: node update_firestore_version.js <version> <build_number> <url>');
    process.exit(1);
  }

  const [version, buildNumber, url] = args;

  try {
    const docRef = db.collection('app_config').doc('update_info');

    // Using merge: true to avoid overwriting force_update or changelog fields if they exist
    await docRef.set({
      latest_version: version,
      latest_build_number: parseInt(buildNumber, 10),
      download_url: url
    }, { merge: true });

    console.log(`Successfully updated Firestore with version ${version} (${buildNumber})`);
    process.exit(0);
  } catch (error) {
    console.error('Error updating Firestore:', error);
    process.exit(1);
  }
}

updateVersion();
