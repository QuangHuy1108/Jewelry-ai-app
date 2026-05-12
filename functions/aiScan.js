const functions = require('firebase-functions');
const OpenAI = require('openai');

exports.aiScan = functions.https.onRequest(async (req, res) => {
  // CORS configuration
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    return res.status(204).send('');
  }

  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const { imageUrl } = req.body;
  
  if (!imageUrl) {
    return res.status(400).json({ error: 'Missing imageUrl in request body' });
  }

  try {
    // We assume the OpenAI API key is stored securely in environment vars or Firebase config
    // E.g. process.env.OPENAI_API_KEY
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY || functions.config().openai?.key, // standard fallback bindings
    });

    const response = await openai.chat.completions.create({
      model: "gpt-4-vision-preview",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "Analyze this jewelry image and return JSON with:\n- type (ring, necklace, bracelet, etc.)\n- material (gold, silver, platinum, etc.)\n- gemstone (diamond, ruby, sapphire, none)\n- style (luxury, vintage, minimalist, etc.)\n- estimated_price_range\n\nReturn ONLY JSON, no markdown wrappers."
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

    let rawOutput = response.choices[0].message.content;
    
    // Strip markdown formatting if it accidentally injected it
    if (rawOutput.startsWith('```json')) {
      rawOutput = rawOutput.replace(/```json\n?/, '').replace(/\n?```/, '');
    } else if (rawOutput.startsWith('```')) {
      rawOutput = rawOutput.replace(/```\n?/, '').replace(/\n?```/, '');
    }

    const parsedJson = JSON.parse(rawOutput.trim());
    return res.status(200).json(parsedJson);

  } catch (error) {
    console.error('Error parsing jewelry with OpenAI:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});
