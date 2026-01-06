import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import { GoogleAuth } from "google-auth-library";

admin.initializeApp();

const REGION = "us-central1";
const CONVERTER_URL =
  "https://meddeck-ppt-converter-52591950022.us-central1.run.app/convert";

/**
 * Trigger:
 * Runs automatically when a deck status changes to "approved"
 *
 * Expects the deck document to contain either:
 *   A) pptPath (recommended): full storage object path to the pptx
 *      e.g. "ppts/<uid>/<filename>.pptx"
 *   OR
 *   B) deckId-based convention fallback: "ppts/{deckId}/..." (first pptx found)
 *
 * Writes back:
 *  - slides: string[] (storage paths returned by Cloud Run)
 *  - slideCount: number
 *  - pdfPages: number | null
 *  - coverSlide: string | null (first slide path)
 *  - conversionStatus: "done" | "error" | "converting"
 *  - conversionError: string | null
 *  - convertedAt: server timestamp
 */
export const onDeckApproved = onDocumentUpdated(
  {
    document: "decks/{deckId}",
    region: REGION,
    retry: true
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const deckId = event.params.deckId;

    if (!before || !after) return;

    // Only run when status transitions -> approved
    if (after.status !== "approved" || before.status === "approved") return;

    // Idempotency: if already converted, skip
    if (Array.isArray(after.slides) && after.slides.length > 0) {
      logger.info("Slides already exist, skipping conversion", { deckId });
      return;
    }

    const bucket = (after.bucket as string) || "meddeck-4cb95.firebasestorage.app";

    // Prefer explicit pptPath stored on the doc (best)
    let pptPath: string | null = (after.pptPath as string) || null;

    // Fallback: try to find the first ppt/pptx under ppts/{deckId}
    if (!pptPath) {
      const storageBucket = admin.storage().bucket(bucket);
      const prefix = `ppts/${deckId}`;
      const [files] = await storageBucket.getFiles({ prefix });

      const ppt = files.find((f) => f.name.toLowerCase().endsWith(".pptx")) ||
                  files.find((f) => f.name.toLowerCase().endsWith(".ppt"));

      if (!ppt) {
        logger.error("No PPT/PPTX found for deck", { deckId, prefix, bucket });
        await admin.firestore().doc(`decks/${deckId}`).update({
          conversionStatus: "error",
          conversionError: `No PPT/PPTX found in Storage under ${prefix}`
        });
        return;
      }

      pptPath = ppt.name;
    }

    // Mark converting
    await admin.firestore().doc(`decks/${deckId}`).update({
      conversionStatus: "converting",
      conversionError: null,
      convertedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    try {
      // Mint ID token for Cloud Run and call converter
      const auth = new GoogleAuth();
      const client = await auth.getIdTokenClient(CONVERTER_URL);

      const resp = await client.request({
        url: CONVERTER_URL,
        method: "POST",
        data: {
          bucket,
          filePath: pptPath
        }
      });

      const data = resp.data as any;

      if (!data || data.status !== "ok") {
        throw new Error(`Converter returned non-ok: ${JSON.stringify(data)}`);
      }

      const slides: string[] = Array.isArray(data.slides) ? data.slides : [];
      const pdfPages: number | null =
        typeof data.pdfPages === "number" ? data.pdfPages : null;

      await admin.firestore().doc(`decks/${deckId}`).update({
        slides,
        slideCount: slides.length,
        pdfPages,
        coverSlide: slides.length > 0 ? slides[0] : null,
        conversionStatus: "done",
        conversionError: null,
        convertedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info("Deck conversion complete", {
        deckId,
        slideCount: slides.length,
        pdfPages
      });
    } catch (err: any) {
      logger.error("Deck conversion failed", {
        deckId,
        message: err?.message ?? String(err)
      });

      await admin.firestore().doc(`decks/${deckId}`).update({
        conversionStatus: "error",
        conversionError: err?.message ?? String(err)
      });

      throw err; // allow retry
    }
  }
);
