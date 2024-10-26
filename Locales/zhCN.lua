﻿--Contributors: It's a ME!
if not (GetLocale() == "zhCN") then return end;

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = "日常";
L["Quest Frequency Weekly"] = "周常";

L["Quest Type Repeatable"] = "可重复";
L["Quest Type Trivial"] = "低等级";    --Low-level quest
L["Quest Type Dungeon"] = "地下城任务";
L["Quest Type Raid"] = "团本任务";
L["Quest Type Covenant Calling"] = "盟约使命";

L["Accept"] = "接受"
L["Continue"] = "继续";
L["Complete Quest"] = "完成任务";
L["Incomplete"] = "未完成";
L["Cancel"] = "取消";
L["Goodbye"] = "再见";
L["Decline"] = "拒绝";
L["OK"] = "OK";
L["Quest Objectives"] = "任务目标";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = "奖励";
L["Rewards"] = "奖励";
L["War Mode Bonus"] = "战争模式加成";
L["Honor Points"] = "荣誉";
L["Symbol Gold"] = "金";
L["Symbol Silver"] = "银";
L["Symbol Copper"] = "铜";
L["Requirements"] = "所需条件";
L["Current Colon"] = "当前：";
L["Renown Level Label"] = "名望 ";  --There is a space
L["Abilities"] = "技能";
L["Traits"] = "专长";
L["Costs"] = "费用";   --The costs to continue an action, usually gold
L["Ready To Enter"] = "准备进入";
L["Show Comparison"] = "显示物品对比";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "隐藏物品对比";
L["Copy Text"] = "复制文本";
L["To Next Level Label"] = "距下一级";
L["Quest Accepted"] = "已接受任务";
L["Quest Log Full"] = "任务日志已满";
L["Quest Auto Accepted Tooltip"] = "游戏自动接受了这个任务。";
L["Level Maxed"] = "已满级";   --Reached max level
L["Paragon Reputation"] = "巅峰";
L["Different Item Types Alert"] = "物品种类不同！";
L["Click To Read"] = "左键点击阅读";
L["Item Level"] = "物品等级";
L["Gossip Quest Option Prepend"] = "（任务）";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "左键点击： 播放/停止阅读\n右键点击： 勾选自动播放";
L["Item Is An Upgrade"] = "这件装备对你有提升";
L["Identical Stats"] = "这两件装备的属性相同";
L["Quest Completed On Account"] = "你的战团此前已经完成了这个任务。";
L["New Quest Available"] = "发现新任务";
L["Campaign Quest"] =  "战役";
L["Click To Open BtWQuests"] = "点击以在BtWQuests窗口中查看此任务。";
L["Story Progress"] = "故事进度";

--String Format
L["Format Reputation Reward Tooltip"] = "在%2$s中的声望提高%1$d点";
L["Format You Have X"] = "- 你拥有 |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- 你拥有 |cffffffff%d|r (|cffffffff%d|r 个在银行)";
L["Format Suggested Players"] = "建议玩家人数：[%d]";
L["Format Current Skill Level"] = "当前等级：|cffffffff%d/%d|r";
L["Format Reward Title"] = "头衔：%s";
L["Format Follower Level Class"] = "等级%d %s";
L["Format Monster Say"] = "%s说： ";
L["Format Quest Accepted"] = "接受任务：%s";
L["Format Quest Completed"] = "%s完成。"
L["Format Player XP"] = "经验值：%d/%d (%d%%)";
L["Format Gold Amount"] = "%d金";
L["Format Silver Amount"] = "%d银";
L["Format Copper Amount"] = "%d铜";
L["Format Unit Level"] = "等级 %d";
L["Format Replace Item"] = "替换 %s";
L["Format Item Level"] = "物品等级 %d";
L["Format Breadcrumb Quests Available"] = "可接受引导性任务：";
L["Format Functionality Handled By"] = "此功能由以下插件处理：%s";
L["Format Time Left"] = "剩余时间：%s";
L["Format Your Progress"] = "你的进度：|cffffffff%d/%d|r";
L["Format And More"] = "更多%d……";
L["Format Chapter Progress"] = "%d/%d 章";
L["Format Quest Progress"] = "%d/%d 任务";

--Settings
L["UI"] = "界面";
L["Camera"] = "镜头";
L["Control"] = "控制";
L["Gameplay"] = "游戏功能";
L["Accessibility"] = "辅助功能";

L["Option Enabled"] = "已启用";
L["Option Disabled"] = "已禁用";
L["Move Position"] = "移动";
L["Reset Position"] = "重置位置";
L["Drag To Move"] = "左键点击并拖拽以移动该窗口。";
L["Middle Click To Reset Position"] = "中键点击以重置位置。";

L["Quest"] = "任务";
L["Gossip"] = "对话";
L["Theme"] = "主题";
L["Theme Desc"] = "选择一个主题色。";
L["Theme Brown"] = "棕色";
L["Theme Dark"] = "深色";
L["Frame Size"] = "界面大小";
L["Frame Size Desc"] = "改变对话界面的大小。";
L["Size Extra Small"] = "特小";
L["Size Small"] = "小";
L["Size Medium"] = "中";
L["Size Large"] = "大";
L["Font Size"] = "字号";
L["Font Size Desc"] = "改变整个界面的字号。";
L["Frame Orientation"] = "界面位置";
L["Frame Orientation Desc"] = "把任务界面放在屏幕左侧或右侧。";
L["Orientation Left"] = "左侧";
L["Orientation Right"] = "右侧";
L["Hide UI"] = "隐藏界面";
L["Hide UI Desc"] = "与NPC交互时隐藏其他界面。";
L["Hide Unit Names"] = "隐藏单位姓名";
L["Hide Unit Names Desc"] = "与NPC交互时隐藏其他玩家和NPC的名字。";
L["Show Copy Text Button"] = "显示复制文本按钮";
L["Show Copy Text Button Desc"] = "在对话界面的右上角显示复制文本按钮。";
L["Show Quest Type Text"] = "显示任务类型";
L["Show Quest Type Text Desc"] = "在任务按钮的右侧以文字形式显示任务类型，如果它较为特殊的话。\n\n低等级任务总是会被提示。";
L["Show NPC Name On Page"] = "显示NPC名字";
L["Show NPC Name On Page Desc"] = "在页面上显示交互对象的名字。";
L["Show Warband Completed Quest"] = "标注战团已完成的任务";
L["Show Warband Completed Quest Desc"] = "如果你已在其他角色上完成当前任务，在任务详情界面的底部添加注释。";
L["Simplify Currency Rewards"] = "简化货币显示";
L["Simplify Currency Rewards Desc"] = "用更小的图标来显示货币奖励，货币名称也会被省略。";
L["Mark Highest Sell Price"] = "标记出最值钱的物品";
L["Mark Highest Sell Price Desc"] = "在你选择任务奖励时标记出卖店价格最高的物品。";
L["Use Blizzard Tooltip"] = "使用暴雪鼠标提示";
L["Use Blizzard Tooltip Desc"] = "使用暴雪自带的鼠标提示来显示任务奖励详情。";
L["Roleplaying"] = "角色扮演";
L["Use RP Name In Dialogues"] = "对话中使用RP名字";
L["Use RP Name In Dialogues Desc"] = "将对话文本中出现的本名替换为你RP角色的名字。";

L["Camera Movement"] = "镜头运动";
L["Camera Movement Off"] = "关";
L["Camera Movement Zoom In"] = "拉近";
L["Camera Movement Horizontal"] = "平移";
L["Maintain Camera Position"] = "保持镜头位置";
L["Maintain Camera Position Desc"] = "在NPC交互结束后短暂地保持镜头位置。\n\n勾选此选项可以减少由任务对话延迟等原因导致的镜头快速变化的情况。";
L["Change FOV"] = "改变视角";
L["Change FOV Desc"] = "降低镜头视角来让NPC在画面中占的比例更大。";
L["Disable Camera Movement Instance"] = "副本中关闭";
L["Disable Camera Movement Instance Desc"] = "在副本中关闭镜头运动。";
L["Maintain Offset While Mounted"] = "在骑乘时保持水平位移";
L["Maintain Offset While Mounted Desc"] = "在你上坐骑后尝试保持你的角色在屏幕上的位置不变。\n\n勾选此选项可能会导致在你使用体形比较大的坐骑时镜头出现过度补偿。";

L["Input Device"] = "输入设备";
L["Input Device Desc"] = "此选项影响快捷键图标和界面布局。";
L["Input Device KBM"] = "键鼠";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "确认键： [KEY:XBOX:PAD1]\n取消键： [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "确认键： [KEY:PS:PAD1]\n取消键： [KEY:PS:PAD2]";
L["Input Device Switch"] = "Switch";
L["Input Device Switch Tooltip"] = "确认键： [KEY:SWITCH:PAD1]\n取消键： [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "确认键";
L["Primary Control Key Desc"] = "按下此按钮将自动选择第一个最佳选项，例如接受任务。"
L["Press Button To Scroll Down"] = "按确认键来向下滚屏";
L["Press Button To Scroll Down Desc"] = "如果当前页面盛不下所有任务文本，按下确认键会向下滚屏而不是接受任务。";
L["Right Click To Close UI"] = "右键关闭界面";
L["Right Click To Close UI Desc"] = "在对话界面上按右键即可关闭窗口。";
L["Press Tab To Select Reward"] = "按Tab键选择任务奖励";
L["Press Tab To Select Reward Desc"] = "在你交任务时，按[KEY:PC:TAB]在可选奖励之间循环。";
L["Experimental Features"] = "实验性";
L["Emulate Swipe"] = "模拟滑动手势";
L["Emulate Swipe Desc"] = "在对话界面上点击并拖拽来滚动页面。";
L["Mobile Device Mode"] = "移动设备模式";
L["Mobile Device Mode Desc"] = "实验性功能：\n\n增大界面和字号来让文本在小屏幕设备上也可清晰分辨。";
L["Mobile Device Mode Override Option"] = "此选项暂时不起作用，因为你已在控制选项里开启“移动设备”模式";

L["Key Space"] = "空格";
L["Key Interact"] = "交互键";
L["Cannot Use Key Combination"] = "不支持组合键。";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] 你没有绑定交互键。"
L["Use Default Control Key Alert"] = "将继续使用 [KEY:PC:SPACE] 作为确认键。";
L["Key Disabled"] = "不做设定";
L["Key Disabled Tooltip"] = "不再使用确认键。\n\n你将无法通过按键盘的方式来接受任务。";

L["Auto Quest Popup"] = "自动任务弹窗";
L["Auto Quest Popup Desc"] = "如果一个新任务是由拾取物品或进入某区域后自动触发的，先用小弹窗显示这个任务。\n\n那些在你登录后就自动弹出的任务可能不满足我们的判定条件。";
L["Popup Position"] = "弹窗位置";    --Pop-up window position
L["Widget Is Docked Generic"] = "此窗口与其他弹窗停靠在一起。";   --Indicate a window is docked with other pop-up windows
L["Widget Is Docked Named"] = "%s与其他弹窗停靠在一起。";
L["Quest Item Display"] = "任务物品说明";
L["Quest Item Display Desc"] = "自动显示任务物品上的说明，并且允许你在不打开背包的情况下就能使用它。";
L["Quest Item Display Hide Seen"] = "忽略见过的物品";
L["Quest Item Display Hide Seen Desc"] = "忽略你账号上角色见过的物品。";
L["Quest Item Display Await World Map"] = " 等待世界地图";
L["Quest Item Display Await World Map Desc"] = "当你打开世界地图时，将正在显示的任务物品说明隐藏并暂停自动关闭倒计时。";
L["Quest Item Display Reset Position Desc"] = "重置窗口位置。";
L["Auto Select"] = "自动选择";
L["Auto Select Gossip"] = "自动选择对话选项";
L["Auto Select Gossip Desc"] = "当你与特定NPC交互时自动选择最合适的选项。";
L["Force Gossip"] = "强制显示对话";
L["Force Gossip Desc"] = "在游戏默认状态下，系统有时会自动选择第一个选项且不显示对话界面。勾选强制显示对话将显示这些被隐藏的内容。";
L["Show Hint"] = "显示正确答案";
L["Show Hint Desc"] = "增加一个选项来自动选择正确的对话答案。\n\n目前仅支持时空漫游期间的问答日常。";
L["Nameplate Dialog"] = "在姓名版上显示对话";
L["Nameplate Dialog Desc"] = "将不提供任何选项的对话显示在目标姓名版上。\n\n此选项将修改CVar \"SoftTarget Nameplate Interact\"";
L["Compatibility"] = "兼容性";
L["Disable DUI In Instance"] = "在副本内使用游戏原始对话界面";
L["Disable DUI In Instance Desc"] = "当你进入地下城或团本时使用游戏原始对话界面。\n\n推荐勾选此选项如果你无法与开始或跳过Boss战的NPC交互。";

L["TTS"] = TEXT_TO_SPEECH or "文字转语音";
L["TTS Desc"] = "点击位于任务界面左上角的按钮来朗读文本。\n\n语音，音量大小和速度将跟随魔兽自带的文字转语音设置。";
L["TTS Use Hotkey"] = "使用快捷键";
L["TTS Use Hotkey Desc"] = "按下此按钮来播放或停止朗读：";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "自动播放";
L["TTS Auto Play Desc"] = "自动朗读对话文本。";
L["TTS Skip Recent"] = "跳过最近朗读过的内容";
L["TTS Skip Recent Desc"] = "跳过最近朗读过的内容。";
L["TTS Auto Play Delay"] = "延迟阅读";
L["TTS Auto Play Delay Desc"] = "在自动播放前增加一个短暂的延迟来避免文本朗读与NPC自带语音重叠。";
L["TTS Auto Stop"] = "离开时停止";
L["TTS Auto Stop Desc"] = "在你离开NPC时停止朗读文本。";
L["TTS Stop On New"] = "开始新对话时停止";
L["TTS Stop On New Desc"] = "在你浏览新对话时停止之前在朗读的文本。";
L["TTS Voice Male"] = "男性角色声音";
L["TTS Voice Male Desc"] = "当你与男性角色交互时使用此声音：";
L["TTS Voice Female"] = "女性角色声音";
L["TTS Voice Female Desc"] = "当你与女性角色交互时使用此声音：";
L["TTS Use Narrator"] = "旁白";
L["TTS Use Narrator Desc"] = "使用另一种声音来朗读NPC名字、任务名称、任务目标以及任何尖括号内的内容。";
L["TTS Voice Narrator"] = "声音";
L["TTS Voice Narrator Desc"] = "旁白将使用此声音：";
L["TTS Volume"] = "音量";
L["TTS Volume Desc"] = "调节朗读声音的音量。";
L["TTS Rate"] = "语速";
L["TTS Rate Desc"] = "调节朗读声音的语速。";
L["TTS Include Content"] = "朗读以下内容";
L["TTS Content NPC Name"] = "NPC名字";
L["TTS Content Quest Name"] = "任务名称";
L["TTS Content Objective"] = "任务目标";

--Book UI and Settings
L["Readables"] = "可阅读物品";   --Readable Objects
L["Readable Objects"] = "可阅读物品";     --Used as a label for a setting in Accessibility-TTS
L["BookUI Enable"] = "使用新UI";
L["BookUI Enable Desc"] = "使用新UI显示可阅读物品如书籍和信件。";
L["BookUI Frame Size Desc"] = "改变书籍界面的大小。";
L["BookUI Keep UI Open"] = "保持窗口打开";
L["BookUI Keep UI Open Desc"] = "当你远离物体时不自动关闭窗口。按Esc或在界面上按右键来关闭它。";
L["BookUI Show Location"] = "显示地点";
L["BookUI Show Location Desc"] = "在标题上方显示物体的地点。仅限于环境中的物体，不适用于背包内的物品。";
L["BookUI Show Item Description"] = "显示物品描述";
L["BookUI Show Item Description Desc"] = "若物品有描述，则在书籍界面上方显示它。";
L["BookUI Darken Screen"] = "屏幕变暗";
L["BookUI Darken Screen Desc"] = "让界面后方区域变暗来帮助你将注意力集中在内容上。";
L["BookUI TTS Voice"] = "声音";
L["BookUI TTS Voice Desc"] = "使用此声音朗读书籍：";
L["BookUI TTS Click To Read"] = "点击以朗读段落";
L["BookUI TTS Click To Read Desc"] = "左键点击某个段落来朗读它。\n\n左键点击正在被朗读的段落即可停止。";

--Tutorial
L["Tutorial Settings Hotkey"] = "按下 [KEY:PC:F1] 来打开或关闭设置";
L["Tutorial Settings Hotkey Console"] = "按下 [KEY:PC:F1] 或 [KEY:CONSOLE:MENU] 来打开或关闭设置";   --Use this if gamepad enabled
L["Instuction Open Settings"] = "在与NPC交互时按下 [KEY:PC:F1] 来打开设置";    --Used in Game Menu - AddOns
L["Instuction Open Settings Console"] = "在与NPC交互时按下 [KEY:PC:F1] 或 [KEY:CONSOLE:MENU] 来打开设置";

--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = "千";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = "万";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "([,%d%.]+)点护甲";
L["Match Stat Stamina"] = "([,%d%.]+) 耐力";
L["Match Stat Strengh"] = "([,%d%.]+) 力量";
L["Match Stat Agility"] = "([,%d%.]+) 敏捷";
L["Match Stat Intellect"] = "([,%d%.]+) 智力";
L["Match Stat Spirit"] = "([,%d%.]+) 精神";
L["Match Stat DPS"] = "每秒伤害([,%d%.]+)";

L["Show Answer"] = "显示正确答案。";

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = "拍卖行";
L["Pin Bank"] = "银行";
L["Pin Barber"] = "理发师";
L["Pin Battle Pet Trainer"] = "战斗宠物训练师";
L["Pin Crafting Orders"] = "制造订单";
L["Pin Flight Master"] = "飞行管理员";
L["Pin Great Vault"] = "宏伟宝库";
L["Pin Inn"] = "旅店";
L["Pin Item Upgrades"] = "物品升级";
L["Pin Mailbox"] = "邮箱";
L["Pin Other Continents"] = "其他大陆";
L["Pin POI"] = "名胜地";
L["Pin Profession Trainer"] = "专业训练师";
L["Pin Rostrum"] = "幻形讲坛";
L["Pin Stable Master"] = "兽栏管理员";
L["Pin Trading Post"] = "商栈";