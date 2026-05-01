require('dotenv').config();

const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

function formatCurrency(value) {
  const number = Number(value || 0);
  return `Rp ${number.toLocaleString('id-ID')}`;
}

function buildContextSummary(context) {
  const debts = Array.isArray(context?.debts) ? context.debts : [];
  const totalRemaining = debts.reduce(
    (sum, item) => sum + Number(item.remaining || 0),
    0,
  );
  const lines = [
    `Penghasilan bulanan: ${formatCurrency(context?.monthlyIncome)}`,
    `Budget tambahan: ${formatCurrency(context?.extraBudget)}`,
    `Jumlah hutang aktif: ${debts.length}`,
    `Total sisa hutang: ${formatCurrency(totalRemaining)}`,
  ];

  if (debts.length > 0) {
    lines.push('Daftar hutang:');
    debts.forEach((item, index) => {
      lines.push(
        `${index + 1}. ${item.title} | sisa ${formatCurrency(
          item.remaining,
        )} | cicilan ${formatCurrency(item.monthly)} | tenor ${item.months} bulan`,
      );
    });
  }

  return lines.join('\n');
}

function buildPlanPrompt(context) {
  const strategy = context?.strategy === 'avalanche' ? 'avalanche' : 'snowball';
  const summary = buildContextSummary(context);

  return [
    'Buat rencana bayar hutang yang realistis untuk pengguna Indonesia.',
    `Strategi: ${strategy}.`,
    'Gunakan bahasa Indonesia yang jelas dan ringkas.',
    'Output format: judul singkat, lalu 3-6 poin aksi praktis.',
    'Jika budget tambahan 0, sarankan langkah hemat yang ringan.',
    'Selalu utamakan cicilan minimum agar tidak telat.',
    'Data pengguna:',
    summary,
  ].join('\n');
}

function buildSystemPrompt(mode) {
  const base =
    'Kamu adalah Neistat AI Assistant, membantu manajemen finansial dan hutang. ' +
    'Jawab ringkas, empatik, dan fokus pada langkah praktis. ' +
    'Hindari jargon berat dan jangan memberi janji pasti.';

  if (mode === 'plan') {
    return base +
      ' Fokus pada strategi bayar hutang (snowball/avalanche).';
  }

  return base +
    ' Jawab pertanyaan seputar budgeting, cicilan, dan prioritas keuangan.';
}

app.post('/api/assistant', async (req, res) => {
  try {
    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({ error: 'OPENAI_API_KEY belum diatur' });
    }

    const { mode, messages, context } = req.body || {};

    if (!mode) {
      return res.status(400).json({ error: 'Mode wajib diisi' });
    }

    const chatMessages = [{ role: 'system', content: buildSystemPrompt(mode) }];

    if (mode === 'chat') {
      chatMessages.push({
        role: 'user',
        content: `Konteks pengguna:\n${buildContextSummary(context)}`,
      });

      if (Array.isArray(messages)) {
        messages.forEach((msg) => {
          if (msg?.role && msg?.content) {
            chatMessages.push({ role: msg.role, content: msg.content });
          }
        });
      }
    } else if (mode === 'plan') {
      chatMessages.push({
        role: 'user',
        content: buildPlanPrompt(context),
      });
    } else {
      return res.status(400).json({ error: 'Mode tidak dikenal' });
    }

    const completion = await client.chat.completions.create({
      model,
      temperature: 0.3,
      messages: chatMessages,
    });

    const reply = completion.choices?.[0]?.message?.content?.trim() || '';
    res.json({ reply });
  } catch (error) {
    const status = error?.status || error?.statusCode || 500;
    const message = error?.message || 'Unexpected error';
    console.error('AI proxy error', {
      status,
      message,
      type: error?.type,
      code: error?.code,
    });
    res.status(500).json({ error: message });
  }
});

const port = Number(process.env.PORT || 5050);
app.listen(port, () => {
  console.log(`AI proxy running on http://localhost:${port}`);
});
