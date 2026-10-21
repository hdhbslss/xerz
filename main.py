import sqlite3, io, math
from datetime import datetime
import discord
from discord import app_commands
from discord.ext import commands

# ============ 設定區（改這裡） ============
TOKEN = "MTU2MjQ3ODkxMTE2ODcxMjgwNA.Gdm04x.IvOdLHf0IAYbZlPja0e1kdYCzNFJrNJKWmkLHM"
GUILD_ID = 1529849780275118182          # 伺服器ID
# =========================================

db = sqlite3.connect("data.db")
db.executescript("""
CREATE TABLE IF NOT EXISTS panels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT UNIQUE,
    channel_id TEXT,
    title TEXT,
    content TEXT,
    max_players INTEGER,
    team_size INTEGER,
    closed INTEGER DEFAULT 0,
    created_at TEXT
);
CREATE TABLE IF NOT EXISTS signups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    panel_id INTEGER NOT NULL,
    user_id TEXT NOT NULL,
    device TEXT NOT NULL,
    account_id TEXT NOT NULL,
    status TEXT DEFAULT 'approved',
    created_at TEXT,
    UNIQUE(panel_id, user_id)
);
""")
db.commit()

cols = [r[1] for r in db.execute("PRAGMA table_info(panels)").fetchall()]
if "closed" not in cols:
    db.execute("ALTER TABLE panels ADD COLUMN closed INTEGER DEFAULT 0")
    db.commit()

def create_panel(msg_id, ch_id, title, content, max_players, team_size):
    cur = db.execute(
        "INSERT INTO panels(message_id, channel_id, title, content, max_players, team_size, created_at) "
        "VALUES(?,?,?,?,?,?,?)",
        (str(msg_id), str(ch_id), title, content, max_players, team_size,
         datetime.now().isoformat(timespec="seconds"))
    )
    db.commit()
    return cur.lastrowid

def get_panel(pid):
    return db.execute(
        "SELECT id, title, content, max_players, team_size, closed FROM panels WHERE id=?", (pid,)
    ).fetchone()

def get_panel_by_message(msg_id):
    return db.execute(
        "SELECT id, title, content, max_players, team_size, closed FROM panels WHERE message_id=?",
        (str(msg_id),)
    ).fetchone()

def get_channel_id(pid):
    row = db.execute("SELECT channel_id FROM panels WHERE id=?", (pid,)).fetchone()
    return int(row[0]) if row else None

def close_panel(pid):
    db.execute("UPDATE panels SET closed=1 WHERE id=?", (pid,))
    db.commit()

def count_signups(pid):
    return db.execute("SELECT COUNT(*) FROM signups WHERE panel_id=?", (pid,)).fetchone()[0]

def has_signed(pid, user_id):
    return db.execute(
        "SELECT 1 FROM signups WHERE panel_id=? AND user_id=?", (pid, str(user_id))
    ).fetchone() is not None

def add_signup(pid, user_id, device, account_id):
    db.execute(
        "INSERT INTO signups(panel_id, user_id, device, account_id, created_at) VALUES(?,?,?,?,?)",
        (pid, str(user_id), device, account_id, datetime.now().isoformat(timespec="seconds"))
    )
    db.commit()

def all_signups(pid):
    return db.execute(
        "SELECT id, user_id, device, account_id, created_at FROM signups WHERE panel_id=? ORDER BY id",
        (pid,)
    ).fetchall()

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)
tree = bot.tree

# 自動偵測管理員：有「管理員」或「管理伺服器」權限即可
def is_admin(member):
    perms = getattr(member, "guild_permissions", None)
    return bool(perms and (perms.administrator or perms.manage_guild))

def panel_embed(panel, closed=False):
    pid, title, content, max_players, team_size, _ = panel
    embed = discord.Embed(
        title=title, description=content,
        color=0x95a5a6 if closed else 0x5865f2
    )
    embed.add_field(name="報名人數限制", value=f"{max_players} 人", inline=True)
    embed.add_field(name="一組人數", value=f"{team_size} 人", inline=True)
    embed.add_field(name="目前報名", value=f"{count_signups(pid)}/{max_players}", inline=True)
    embed.set_footer(text="🔒 已結束報名" if closed else "點下方按鈕報名")
    return embed

# ---------- 規則確認 ----------
class ConfirmRulesView(discord.ui.View):
    def __init__(self, panel_id, device, account_id):
        super().__init__(timeout=120)
        self.panel_id = panel_id
        self.device = device
        self.account_id = account_id

    @discord.ui.button(label="繼續", style=discord.ButtonStyle.success, custom_id="rules:continue")
    async def cont(self, interaction: discord.Interaction, button: discord.ui.Button):
        panel = get_panel(self.panel_id)
        if not panel:
            return await interaction.response.edit_message(content="此報名面板已失效。", view=None)
        _, _, _, max_players, team_size, closed = panel
        if closed:
            return await interaction.response.edit_message(content="🔒 此活動已結束報名。", view=None)
        if has_signed(self.panel_id, interaction.user.id):
            return await interaction.response.edit_message(content="你已經報名過這個活動了。", view=None)
        if count_signups(self.panel_id) >= max_players:
            return await interaction.response.edit_message(
                content=f"❌ 已到達報名人數的限制（{max_players} 人），報名已截止。", view=None)
        add_signup(self.panel_id, interaction.user.id, self.device, self.account_id)
        now = count_signups(self.panel_id)
        await interaction.response.edit_message(
            content=f"✅ 報名成功！\n裝置：{self.device}\n帳號ID：{self.account_id}\n"
                    f"目前報名：{now}/{max_players}（每組 {team_size} 人）", view=None)

    @discord.ui.button(label="停止", style=discord.ButtonStyle.danger, custom_id="rules:stop")
    async def stop(self, interaction: discord.Interaction, button: discord.ui.Button):
        await interaction.response.edit_message(content="已停止報名流程。", view=None)

# ---------- 報名表單 ----------
class SignupModal(discord.ui.Modal, title="填寫報名資料"):
    device = discord.ui.TextInput(label="裝置（PC／手把／行動裝置）", required=True, max_length=16)
    account_id = discord.ui.TextInput(label="帳號ID", required=True, max_length=64)

    def __init__(self, panel_id):
        super().__init__()
        self.panel_id = panel_id

    async def on_submit(self, interaction: discord.Interaction):
        device = self.device.value.strip()
        if device not in ("PC", "手把", "行動裝置"):
            return await interaction.response.send_message(
                "裝置請填：PC、手把 或 行動裝置。", ephemeral=True)
        panel = get_panel(self.panel_id)
        if not panel:
            return await interaction.response.send_message("此報名面板已失效。", ephemeral=True)
        _, _, _, max_players, team_size, closed = panel
        if closed:
            return await interaction.response.send_message("🔒 此活動已結束報名。", ephemeral=True)
        if has_signed(self.panel_id, interaction.user.id):
            return await interaction.response.send_message("你已經報名過這個活動了。", ephemeral=True)
        if count_signups(self.panel_id) >= max_players:
            return await interaction.response.send_message(
                f"❌ 已到達報名人數的限制（{max_players} 人），報名已截止。", ephemeral=True)
        await interaction.response.send_message(
            "請問您已經閱讀過規則了嗎？",
            view=ConfirmRulesView(self.panel_id, device, self.account_id.value.strip()),
            ephemeral=True
        )

# ---------- 報名面板 View ----------
class PanelView(discord.ui.View):
    def __init__(self, panel_id):
        super().__init__(timeout=None)
        self.panel_id = panel_id
        panel = get_panel(panel_id) if panel_id else None
        closed = bool(panel[5]) if panel else False
        btn = discord.ui.Button(
            label="已結束報名" if closed else "報名",
            style=discord.ButtonStyle.secondary if closed else discord.ButtonStyle.primary,
            custom_id=f"panel:signup:{panel_id}",
            disabled=closed
        )
        btn.callback = self.signup
        self.add_item(btn)

    async def signup(self, interaction: discord.Interaction):
        panel = get_panel(self.panel_id)
        if not panel:
            return await interaction.response.send_message("此報名面板已失效。", ephemeral=True)
        _, _, _, max_players, team_size, closed = panel
        if closed:
            return await interaction.response.send_message("🔒 此活動已結束報名。", ephemeral=True)
        if has_signed(self.panel_id, interaction.user.id):
            return await interaction.response.send_message("你已經報名過這個活動了。", ephemeral=True)
        if count_signups(self.panel_id) >= max_players:
            return await interaction.response.send_message(
                f"❌ 已到達報名人數的限制（{max_players} 人），報名已截止。", ephemeral=True)
        await interaction.response.send_modal(SignupModal(self.panel_id))

# ---------- 名單面板 ----------
PAGE_SIZE = 10

class SignupListView(discord.ui.View):
    def __init__(self, panel_id, page=0):
        super().__init__(timeout=None)
        self.panel_id = panel_id
        self.page = page
        total = count_signups(panel_id)
        pages = max(1, math.ceil(total / PAGE_SIZE))
        prev = discord.ui.Button(label="上一頁", style=discord.ButtonStyle.secondary,
                                 custom_id=f"list:prev:{panel_id}", disabled=(page <= 0))
        next_ = discord.ui.Button(label="下一頁", style=discord.ButtonStyle.secondary,
                                  custom_id=f"list:next:{panel_id}", disabled=(page >= pages - 1))
        prev.callback = self.prev_page
        next_.callback = self.next_page
        self.add_item(prev)
        self.add_item(next_)

    def build_embed(self):
        panel = get_panel(self.panel_id)
        rows = all_signups(self.panel_id)
        _, title, _, max_players, team_size, closed = panel
        total = len(rows)
        pages = max(1, math.ceil(total / PAGE_SIZE))
        start = self.page * PAGE_SIZE
        chunk = rows[start:start + PAGE_SIZE]
        embed = discord.Embed(
            title=f"📋 {title}｜報名名單",
            color=0x95a5a6 if closed else 0x2ecc71
        )
        embed.description = f"共 **{total}/{max_players}** 人，每組 **{team_size}** 人"
        if not chunk:
            embed.add_field(name="目前無人報名", value="\u200b", inline=False)
        for r in chunk:
            _, uid, device, account_id, _ = r
            embed.add_field(
                name=f"<@{uid}>",
                value=f"裝置：{device}\n帳號ID：`{account_id}`",
                inline=False
            )
        embed.set_footer(text=f"第 {self.page+1}/{pages} 頁" + ("｜🔒 已結束報名" if closed else ""))
        return embed

    async def prev_page(self, interaction: discord.Interaction):
        if not is_admin(interaction.user):
            return await interaction.response.send_message("你沒有權限。", ephemeral=True)
        self.page = max(0, self.page - 1)
        view = SignupListView(self.panel_id, self.page)
        await interaction.response.edit_message(embed=view.build_embed(), view=view)

    async def next_page(self, interaction: discord.Interaction):
        if not is_admin(interaction.user):
            return await interaction.response.send_message("你沒有權限。", ephemeral=True)
        rows = all_signups(self.panel_id)
        pages = max(1, math.ceil(len(rows) / PAGE_SIZE))
        self.page = min(pages - 1, self.page + 1)
        view = SignupListView(self.panel_id, self.page)
        await interaction.response.edit_message(embed=view.build_embed(), view=view)

# ---------- 指令 ----------
@tree.command(name="報名面板", description="建立報名面板（管理員）", guild=discord.Object(id=GUILD_ID))
@app_commands.describe(標題="面板標題", 內容="面板內容（規則、獎品等）",
                       報名人數限制="最多幾人報名", 一組幾人="每組人數")
async def create_panel_cmd(
    interaction: discord.Interaction, 標題: str, 內容: str,
    報名人數限制: app_commands.Range[int, 1, 1000],
    一組幾人: app_commands.Range[int, 1, 100]
):
    if not is_admin(interaction.user):
        return await interaction.response.send_message("你沒有權限。", ephemeral=True)

    embed = discord.Embed(title=標題, description=內容, color=0x5865f2)
    embed.add_field(name="報名人數限制", value=f"{報名人數限制} 人", inline=True)
    embed.add_field(name="一組人數", value=f"{一組幾人} 人", inline=True)
    embed.add_field(name="目前報名", value=f"0/{報名人數限制}", inline=True)
    embed.set_footer(text="點下方按鈕報名")

    await interaction.response.send_message(embed=embed, view=PanelView(0))
    msg = await interaction.original_response()
    panel_id = create_panel(msg.id, msg.channel.id, 標題, 內容, 報名人數限制, 一組幾人)
    await msg.edit(view=PanelView(panel_id))
    bot.add_view(PanelView(panel_id))
    await interaction.followup.send(
        f"✅ 已建立報名面板。\n面板ID：`{msg.id}`\n"
        f"用 `/查看報名名單` 查名單、`/結束報名` 關閉報名。",
        ephemeral=True
    )

@tree.command(name="查看報名名單", description="查看某報名面板的名單（管理員）", guild=discord.Object(id=GUILD_ID))
@app_commands.describe(面板id="報名面板訊息的ID")
async def view_list(interaction: discord.Interaction, 面板id: str):
    if not is_admin(interaction.user):
        return await interaction.response.send_message("你沒有權限。", ephemeral=True)
    try:
        msg_id = int(面板id.strip())
    except ValueError:
        return await interaction.response.send_message("面板ID格式錯誤。", ephemeral=True)
    panel = get_panel_by_message(msg_id)
    if not panel:
        return await interaction.response.send_message("找不到對應的報名面板。", ephemeral=True)
    view = SignupListView(panel[0], 0)
    await interaction.response.send_message(embed=view.build_embed(), view=view, ephemeral=True)

@tree.command(name="結束報名", description="結束某報名面板的報名（管理員）", guild=discord.Object(id=GUILD_ID))
@app_commands.describe(面板id="報名面板訊息的ID")
async def close_panel_cmd(interaction: discord.Interaction, 面板id: str):
    if not is_admin(interaction.user):
        return await interaction.response.send_message("你沒有權限。", ephemeral=True)
    try:
        msg_id = int(面板id.strip())
    except ValueError:
        return await interaction.response.send_message("面板ID格式錯誤。", ephemeral=True)
    panel = get_panel_by_message(msg_id)
    if not panel:
        return await interaction.response.send_message("找不到對應的報名面板。", ephemeral=True)
    pid, title, _, max_players, _, closed = panel
    if closed:
        return await interaction.response.send_message("此面板已經結束報名了。", ephemeral=True)

    close_panel(pid)

    updated = get_panel(pid)
    ch_id = get_channel_id(pid)
    try:
        ch = bot.get_channel(ch_id) or await bot.fetch_channel(ch_id)
        msg = await ch.fetch_message(msg_id)
        await msg.edit(embed=panel_embed(updated, closed=True), view=PanelView(pid))
    except Exception as e:
        print("更新面板訊息失敗：", e)

    total = count_signups(pid)
    await interaction.response.send_message(
        f"🔒 已結束「{title}」的報名。\n最終報名人數：**{total}/{max_players}**",
        ephemeral=True
    )

# ---------- 啟動 ----------
@bot.event
async def on_ready():
    panels = db.execute("SELECT id FROM panels").fetchall()
    for (pid,) in panels:
        bot.add_view(PanelView(pid))
        total = count_signups(pid)
        pages = max(1, math.ceil(total / PAGE_SIZE))
        for p in range(pages):
            bot.add_view(SignupListView(pid, p))
    await tree.sync(guild=discord.Object(id=GUILD_ID))
    print(f"Logged in as {bot.user}，已恢復 {len(panels)} 個報名面板")

bot.run(TOKEN)
