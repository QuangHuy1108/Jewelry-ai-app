const functions = require('firebase-functions');
const OpenAI = require('openai');

exports.aiScan = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Only logged-in users can use AI.');
  }

  const imageUrl = data.imageUrl;
  
  if (!imageUrl) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing imageUrl in request');
  }

  try {
    // We assume the OpenAI API key is stored securely in environment vars or Firebase config
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY || functions.config().openai?.key, // standard fallback bindings
    });

    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "Analyze this jewelry image and return JSON with:\n- type (ring, necklace, bracelet, etc.)\n- material (gold, silver, platinum, etc.)\n- gemstone (diamond, ruby, sapphire, none)\n- style (luxury, vintage, minimalist, etc.)\n- estimated_price_range\n\nReturn ONLY JSON."
            },
            {
              type: "image_url",
              image_url: {
                url: imageUrl
              }
            }
          ]
        }
      ],
      max_tokens: 500,
      temperature: 0.0,
    });

    const rawOutput = response.choices[0].message.content;
    const parsedJson = JSON.parse(rawOutput.trim());
    return parsedJson;

  } catch (error) {
    console.error('Error parsing jewelry with OpenAI:', error);
    throw new functions.https.HttpsError('internal', 'Internal Server Error', error.message);
  }
});
