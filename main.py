#!/usr/bin/env python3
import json
import os
import random

from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import (
    ApplicationBuilder,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

TOKEN = os.environ["BOT_TOKEN"]
DATA_FILE = "scores.json"
MAX_NUMBER = 100

PERSIAN_DIGITS = str.maketrans("۰۱۲۳۴۵۶۷۸۹", "0123456789")


def load_scores() -> dict:
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_scores(scores: dict) -> None:
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(scores, f, ensure_ascii=False, indent=2)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    kb = [[InlineKeyboardButton("🎮 شروع بازی جدید", callback_data="new")]]
    await update.message.reply_text(
        "سلام! 👋\n"
        f"من یک عدد بین ۱ تا {MAX_NUMBER} انتخاب می‌کنم و تو باید حدس بزنی.\n"
        "بعد از هر حدس می‌گم «بالاتر» یا «پایین‌تر».\n\n"
        "هرچی با تلاش کمتر ببری، رکورد بهتری می‌زنی! 🏆",
        reply_markup=InlineKeyboardMarkup(kb),
    )


async def stats(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    scores = context.bot_data["scores"]
    uid = str(update.effective_user.id)
    if uid in scores:
        await update.message.reply_text(
            f"🏆 رکورد تو: {scores[uid]['best']} تلاش\n"
            f"🎯 تعداد بردها: {scores[uid]['wins']}"
        )
    else:
        await update.message.reply_text("هنوز بازی نکردی! با /start شروع کن. 🙂")


async def top(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    scores = context.bot_data["scores"]
    if not scores:
        await update.message.reply_text("هنوز کسی بازی نکرده! 😐")
        return

    best = sorted(scores.items(), key=lambda x: x[1]["best"])[:10]
    lines = ["🏅 <b>بهترین بازیکنان:</b>"]
    for i, (uid, info) in enumerate(best, 1):
        lines.append(f"{i}. {info['name']} — {info['best']} تلاش")

    await update.message.reply_text("\n".join(lines), parse_mode="HTML")


async def new_game(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()
    context.user_data["number"] = random.randint(1, MAX_NUMBER)
    context.user_data["tries"] = 0
    context.user_data["playing"] = True

    await query.edit_message_text(
        f"✅ عدد را انتخاب کردم!\nیک عدد بین ۱ تا {MAX_NUMBER} بفرست:"
    )


async def guess(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not context.user_data.get("playing"):
        await update.message.reply_text("اول با /start یک بازی جدید شروع کن. 🙂")
        return

    text = update.message.text.strip().translate(PERSIAN_DIGITS)
    if not text.lstrip("-").isdigit():
        await update.message.reply_text("فقط یک عدد بفرست! 🔢")
        return

    g = int(text)
    if not 1 <= g <= MAX_NUMBER:
        await update.message.reply_text(f"عدد باید بین ۱ تا {MAX_NUMBER} باشد.")
        return

    number = context.user_data["number"]
    context.user_data["tries"] += 1
    tries = context.user_data["tries"]

    if g < number:
        await update.message.reply_text("⬆️ بالاتر برو!")
    elif g > number:
        await update.message.reply_text("⬇️ پایین‌تر بیا!")
    else:
        context.user_data["playing"] = False

        user = update.effective_user
        uid = str(user.id)
        scores = context.bot_data["scores"]
        rec = scores.get(
            uid,
            {"name": user.first_name, "best": 9999, "wins": 0},
        )

        rec["name"] = user.first_name
        rec["wins"] += 1
        rec["best"] = min(rec["best"], tries)
        scores[uid] = rec
        save_scores(scores)

        kb = [[InlineKeyboardButton("🔄 بازی جدید", callback_data="new")]]
        await update.message.reply_text(
            f"🎉 آفرین! درست حدس زدی.\n"
            f"عدد <b>{number}</b> بود و تو در <b>{tries}</b> تلاش پیدایش کردی.\n"
            f"🏆 بهترین رکوردت: {rec['best']} تلاش",
            reply_markup=InlineKeyboardMarkup(kb),
            parse_mode="HTML",
        )


def main() -> None:
    app = ApplicationBuilder().token(TOKEN).build()
    app.bot_data["scores"] = load_scores()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("stats", stats))
    app.add_handler(CommandHandler("top", top))
    app.add_handler(CallbackQueryHandler(new_game, pattern="^new$"))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, guess))

    print("Bot is running...")
    app.run_polling()


if __name__ == "__main__":
    main()
