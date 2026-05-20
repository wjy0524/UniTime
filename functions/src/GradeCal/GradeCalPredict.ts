import * as functions from "firebase-functions";
import OpenAI from "openai";
import { defineSecret } from "firebase-functions/params";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

export const gradeCalPredict = functions
  .runWith({ secrets: ["OPENAI_API_KEY"] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }

    const openaiKey = OPENAI_API_KEY.value();
    if (!openaiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "OpenAI key missing"
      );
    }

    const openai = new OpenAI({ apiKey: openaiKey });
    const { courseContext, userQuestion } = data;

    const currentWeightedPoints =
      courseContext.currentWeightedPoints ||
      (courseContext.currentGrade * courseContext.totalWeightCompleted) / 100;

    const ungradedWeight = courseContext.remainingWeight;

    const ungradedItemsList =
      courseContext.ungradedItems
        ?.map((item: any) => `${item.name} (${item.weight}% weight)`)
        .join(", ") || "None";

    const gradedItemsList =
      courseContext.completedItems
        ?.map(
          (item: any) =>
            `${item.name}: ${item.score.toFixed(1)}% × ${item.weight}% = ${(
              (item.score * item.weight) /
              100
            ).toFixed(2)} pts`
        )
        .join("\n") || "None";

    const systemPrompt = `You are a Grade Calculator. Calculate MINIMUM scores to reach EXACTLY the target grade.

CURRENT STATUS:
- Current Weighted Points: ${currentWeightedPoints.toFixed(2)} out of 100
- Graded Weight: ${courseContext.totalWeightCompleted}%
- Ungraded Weight: ${ungradedWeight}%

GRADED ITEMS:
${gradedItemsList}

UNGRADED ITEMS (to predict):
${ungradedItemsList}

CALCULATION:
1. Points needed = Target Grade - ${currentWeightedPoints.toFixed(2)}
2. For each ungraded item: Score needed = (Points from item ÷ Item Weight) × 100
3. Points from item = Score × (Weight ÷ 100)

EXAMPLE:
Current = 87 points, Target = 93%, Ungraded = Quiz (5%) + Exam (5%)
- Points needed = 93 - 87 = 6
- Balanced: 3 pts each → Quiz: (3 ÷ 0.05) = 60%, Exam: 60%
- Check: 87 + (60 × 0.05) + (60 × 0.05) = 87 + 3 + 3 = 93 ✓

RULES:
1. All scenarios must equal EXACTLY the target (within 0.5%)
2. Keep scores between 30-95% (no 100%, no extremes)
3. Generate 2-3 balanced scenarios for 2+ items
4. Verify math: Current + sum of (score × weight/100) = Target

OUTPUT (no formulas, no explanations):
To get [X]%, you need:

Scenario 1:
- [Item]: at least [Y]%
- [Item]: at least [Z]%

Scenario 2:
- [Item]: at least [Y]%
- [Item]: at least [Z]%`;

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userQuestion },
        ],
        max_tokens: 300,
        temperature: 0.05,
      });

      return { reply: response.choices[0].message.content };
    } catch (error) {
      console.error("OpenAI Error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate prediction"
      );
    }
  });
