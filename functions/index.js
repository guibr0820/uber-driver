const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

function getDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // raio da Terra em km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// 1️⃣ Quando uma corrida é criada
exports.onRideCreated = functions.firestore
  .document('rides/{rideId}')
  .onCreate(async (snap, context) => {
    const rideId = context.params.rideId;
    console.log("🚕 Nova corrida criada:", rideId);
    await offerRideToNextDriver(rideId, []);
  });

  
// Função central de oferta sequencial
async function offerRideToNextDriver(rideId, triedDrivers) {
  const rideRef = db.collection("rides").doc(rideId);
  const rideSnap = await rideRef.get();
  if (!rideSnap.exists) return;

  const ride = rideSnap.data();
  if (["accepted", "finished", "cancelled"].includes(ride.status)) return;

  const driversSnap = await db
    .collection("drivers")
    .where("online", "==", true)
    .where("available", "==", true)
    .get();

  // Filtrar motoristas já tentados
  let drivers = driversSnap.docs.filter(d => !triedDrivers.includes(d.id));

  // Filtrar motoristas que estão a até 3,5 km da origem da corrida
  drivers = drivers.filter(d => {
    const loc = d.data().driverLocation;
    if (!loc) return false; // ignora motoristas sem localização
    const distance = getDistanceKm(
      ride.origin.lat,
      ride.origin.lng,
      loc.lat,
      loc.lng
    );
    return distance <= 3.5; // até 3,5 km
  });

  /*if (drivers.length === 0) {
    await rideRef.update({ status: "expired" });
    return;
  }*/

  const nextDriver = drivers[0];

  const offerExpiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 30 * 1000)
  );

  await rideRef.update({
    status: "offered",
    currentDriver: nextDriver.id,
    offerExpiresAt,
    triedDrivers: admin.firestore.FieldValue.arrayUnion(nextDriver.id),
  });

  setTimeout(async () => {
    const latest = await rideRef.get();
    if (!latest.exists) return;
    const data = latest.data();
    if (data.status === "offered" && data.currentDriver === nextDriver.id) {
      await offerRideToNextDriver(rideId, data.triedDrivers || []);
    }
  }, 60000); // 60 segundos para o motorista responder
}

// 3️⃣ Quando a corrida é aceita
exports.onRideAccepted = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === "offered" && after.status === "accepted") {
      console.log("✅ Corrida aceita por:", after.driverId);
      await db.collection("drivers").doc(after.driverId).update({
        available: false,
      });
    }
  });

// 4️⃣ Quando a corrida é finalizada
exports.onRideFinished = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "finished" && after.status === "finished") {
      if (!after.driverId) return;
      
      const driverRef = db.collection("drivers").doc(after.driverId);
      const driverSnap = await driverRef.get();

      if (!driverSnap.exists) return;

      const driverData = driverSnap.data();

      await driverRef.update({
        available: driverData.online === true
      });
    }
  });