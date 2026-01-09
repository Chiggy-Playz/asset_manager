// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

Deno.serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  try {
    const { data: file, error: downloadError } = await supabase
      .storage
      .from("app-updates")
      .download("metadata/latest.json");

    if (downloadError || !file) {
      return json(
        { error: "Failed to load update metadata" },
        500,
      );
    }

    const text = await file.text();
    const latest = JSON.parse(text);

    if (!latest.apkPath || !latest.versionCode) {
      return json(
        { error: "Invalid update metadata" },
        500,
      );
    }

    const { data: signed, error: signError } = await supabase
      .storage
      .from("app-updates")
      .createSignedUrl(latest.apkPath, 60 * 15); // URL valid for 15 minutes

    if (signError || !signed) {
      return json(
        { error: "Failed to sign APK URL" },
        500,
      );
    }

    return json({
      versionCode: latest.versionCode,
      versionName: latest.versionName,
      apkUrl: signed.signedUrl,
      sha256: latest.sha256,
    });
  } catch (_error) {
    return json({ error: "Unexpected error" }, 500);
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/check-update' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
