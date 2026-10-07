#!/usr/bin/env python3
import json
import os
import random
import telebot
from telebot import types

DATA_FILE = "scores.json"
MAX_NUMBER = 100

bot = telebot.TeleBot(os.environ["BOT_TOKEN"], parse_mode="HTML")
games = {}
scores = {}

def load_scores():
    if not os.path.exists(DATA_FILE):
        return {}
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def save_scores():
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(scores, f, ensure_ascii=False, indent=2)

def user_id(message):
    return str(message.from_user.id)

def name_of(message):
    return message.from_user.first_name or "بازیکن"

def menu():
    kb = types.ReplyKeyboardMarkup(resize_keyboard=True)
    kb.row("🎮 بازی جدید", "🏆 آمار من")
    kb.row("🥇 برترین‌ها", "❓ راهنما")
    return kb

def start_text():
    return (
        "🍌 <b>به Fruitino خوش آمدی!</b> 🍓\n\n"
        "🎯 من یک عدد بین <b>۱ تا ۱۰۰</b> انتخاب می‌کنم.\n"
        "تو باید با کمترین تعداد حدس پیدایش کنی.\n\n"
        "برای شروع روی «🎮 بازی جدید» بزن."
    )

def start_game(message):
    uid = user_id(message)
    games[uid] = {"number": random.randint(1, MAX_NUMBER), "tries": 0}
    bot.send_message(
        message.chat.id,
        "🎲 <b>عدد انتخاب شد!</b>\n\nیک عدد بین <b>۱ تا ۱۰۰</b> بفرست."
    )

@bot.message_handler(commands=["start"])
def start(message):
    bot.send_message(message.chat.id, start_text(), reply_markup=menu())

@bot.message_handler(commands=["help", "راهنما"])
def help_command(message):
    bot.send_message(
        message.chat.id,
        "📖 <b>راهنمای Fruitino</b>\n\n"
        "🎮 بازی جدید: شروع حدس عدد\n"
        "🏆 آمار من: رکورد و تعداد بردها\n"
        "🥇 برترین‌ها: ۱۰ رکورد برتر\n\n"
        "بعد از شروع بازی، فقط عدد ۱ تا ۱۰۰ را بفرست."
    )

@bot.message_handler(commands=["آمار", "stats"])
def stats(message):
    uid = user_id(message)
    rec = scores.get(uid)
    if not rec:
        bot.send_message(message.chat.id, "هنوز بازی نکردی! 😄")
        return
    bot.send_message(
        message.chat.id,
        f"🏆 <b>آمار تو</b>\n\n"
        f"🎯 بردها: <b>{rec['wins']}</b>\n"
        f"⚡ بهترین رکورد: <b>{rec['best']}</b> تلاش"
    )

@bot.message_handler(commands=["برترین", "top"])
def top(message):
    if not scores:
        bot.send_message(message.chat.id, "هنوز کسی رکوردی ثبت نکرده! 😐")
        return
    best = sorted(scores.values(), key=lambda x: x["best"])[:10]
    lines = ["🥇 <b>۱۰ بازیکن برتر</b>\n"]
    for i, item in enumerate(best, 1):
        lines.append(f"{i}. {item['name']} — {item['best']} تلاش")
    bot.send_message(message.chat.id, "\n".join(lines))

@bot.message_handler(func=lambda m: m.text in ["🎮 بازی جدید", "بازی جدید", "/بازی", "/شروع"])
def new_game(message):
    start_game(message)

@bot.message_handler(func=lambda m: m.text in ["🏆 آمار من", "آمار من"])
def stats_button(message):
    stats(message)

@bot.message_handler(func=lambda m: m.text in ["🥇 برترین‌ها", "برترین‌ها"])
def top_button(message):
    top(message)

@bot.message_handler(func=lambda m: m.text in ["❓ راهنما", "راهنما"])
def help_button(message):
    help_command(message)

@bot.message_handler(content_types=["text"])
def guess(message):
    uid = user_id(message)
    if uid not in games:
        bot.send_message(
            message.chat.id,
            "اول روی «🎮 بازی جدید» بزن تا بازی شروع شود. 🙂",
            reply_markup=menu()
        )
        return

    raw = message.text.strip().replace("۰","0").replace("۱","1").replace("۲","2").replace("۳","3").replace("۴","4").replace("۵","5").replace("۶","6").replace("۷","7").replace("۸","8").replace("۹","9")
    if not raw.isdigit():
        bot.send_message(message.chat.id, "🔢 فقط یک عدد بین ۱ تا ۱۰۰ بفرست.")
        return

    guess_number = int(raw)
    if not 1 <= guess_number <= MAX_NUMBER:
        bot.send_message(message.chat.id, "⚠️ عدد باید بین ۱ تا ۱۰۰ باشد.")
        return

    game = games[uid]
    game["tries"] += 1
    number = game["number"]

    if guess_number < number:
        bot.send_message(message.chat.id, "⬆️ بیشتره! یک عدد بزرگ‌تر بزن.")
        return

    if guess_number > number:
        bot.send_message(message.chat.id, "⬇️ کمتره! یک عدد کوچک‌تر بزن.")
        return

    tries = game["tries"]
    old = scores.get(uid, {"name": name_of(message), "best": 9999, "wins": 0})
    old["name"] = name_of(message)
    old["wins"] += 1
    old["best"] = min(old["best"], tries)
    scores[uid] = old
    save_scores()
    del games[uid]

    bot.send_message(
        message.chat.id,
        f"🎉 <b>آفرین {name_of(message)}!</b>\n\n"
        f"عدد درست <b>{number}</b> بود.\n"
        f"🎯 در <b>{tries}</b> تلاش پیدا کردی.\n"
        f"🏆 بهترین رکوردت: <b>{old['best']}</b> تلاش\n\n"
        "برای بازی دوباره روی «🎮 بازی جدید» بزن.",
        reply_markup=menu()
    )

if __name__ == "__main__":
    scores = load_scores()
    print("Fruitino Bale bot is running...")
    bot.infinity_polling(skip_pending=True)
