import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";

initializeApp();

export const onDeckApproved = onDocumentUpdated(
  "decks/{deckId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before.status === "approved" || after.status !== "approved") return;

    const deckId = event.params.deckId;
    const pptUrl = after.pptUrl;
    if (!pptUrl) return;

    const pptPath = decodeURIComponent(
      pptUrl.split("/o/")[1].split("?")[0]
    );

    await fetch(process.env.CONVERT_ENDPOINT!, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({deckId, pptPath}),
    });
  }
);
