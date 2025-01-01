--Contributors: github.com/Wagerssi
if not (GetLocale() == "koKR") then return end;

local _, addon = ...
local L = addon.L;


L["Quest Frequency Daily"] = "일일";
L["Quest Frequency Weekly"] = "주간";

L["Quest Type Repeatable"] = "반복 가능";
L["Quest Type Trivial"] = "저레벨";    --Low-level quest
L["Quest Type Dungeon"] = "던전";
L["Quest Type Raid"] = "레이드";
L["Quest Type Covenant Calling"] = "계약 호출";

L["Accept"] = "동의";
L["Continue"] = "계속";
L["Complete Quest"] = "퀘스트 완료";
L["Incomplete"] = "미완성";
L["Cancel"] = "취소";
L["Goodbye"] = "잘가요.";
L["Decline"] = "거절";
L["OK"] = "OK";
L["Quest Objectives"] = "목표";   --We use the shorter one, not QUEST_OBJECTIVES
L["Reward"] = "보상";
L["Rewards"] = "보상들";
L["War Mode Bonus"] = "전쟁모드 보너스";
L["Honor Points"] = "명예";
L["Symbol Gold"] = "골드";
L["Symbol Silver"] = "실버";
L["Symbol Copper"] = "쿠퍼";
L["Requirements"] = "요구 사항들";
L["Current Colon"] = "현재: ";
L["Renown Level Label"] = "명성 ";  --There is a space
L["Abilities"] = "능력";
L["Traits"] = "특성";
L["Costs"] = "비용";   --The costs to continue an action, usually gold
L["Ready To Enter"] = "진입 준비";
L["Show Comparison"] = "비교 표시";   --Toggle item comparison on the tooltip
L["Hide Comparison"] = "비교 숨기기";
L["Copy Text"] = "문자 복사";
L["To Next Level Label"] = "다음 레벨";
L["Quest Accepted"] = "퀘스트 수락";
L["Quest Log Full"] = "퀘스트 목록이 가득 참";
L["Quest Auto Accepted Tooltip"] = "이 퀘스트는 자동으로 수락 됩니다.";
L["Level Maxed"] = "(최대)";   --Reached max level
L["Paragon Reputation"] = "명예";
L["Different Item Types Alert"] = "아이템 유형이 다릅니다!";
L["Click To Read"] = "왼쪽 클릭하여 읽기";
L["Item Level"] = "아이템 레벨";
L["Gossip Quest Option Prepend"] = "(퀘스트)";   --Some gossip options start with blue (Quest), we prioritize them when sorting. See GOSSIP_QUEST_OPTION_PREPEND
L["TTS Button Tooltip"] = "왼쪽 클릭: 읽기 재생/정지.\n오른쪽 클릭: 자동 재생 전환";
L["Item Is An Upgrade"] = "이 아이템은 업그레이드 되었습니다.";
L["Identical Stats"] = "두 장비의 스탯은 동일합니다.";   --Two items provide the same stats
L["Quest Completed On Account"] = "전투부대가 이전에 이 퀘스트를 완료했습니다.";
L["New Quest Available"] = "새로운 퀘스트 발견";

--String Format
L["Format Reputation Reward Tooltip"] = "%s로 %d 평판 획득";
L["Format You Have X"] = "- 보유중 |cffffffff%d|r";
L["Format You Have X And Y In Bank"] = "- 은행에 |cffffffff%d|r (|cffffffff%d|r 보유중)";
L["Format Suggested Players"] = QUEST_SUGGESTED_GROUP_NUM or "추천 플레이어 [%d]";
L["Format Current Skill Level"] = "현재 레벨: |cffffffff%d/%d|r";
L["Format Reward Title"] = "타이틀: %s";
L["Format Follower Level Class"] = "레벨 %d %s";
L["Format Monster Say"] = "%s 말하다: ";
L["Format Quest Accepted"] = "퀘스트 수락: %s";
L["Format Quest Completed"] = "%s 완료.";
L["Format Player XP"] = "경험치: %d/%d (%d%%)";
L["Format Gold Amount"] = "%d 골드";
L["Format Silver Amount"] = "%d 실버";
L["Format Copper Amount"] = "%d 쿠퍼";
L["Format Unit Level"] = "레벨 %d";
L["Format Replace Item"] = "교체 %s";
L["Format Item Level"] = "아이템 레벨 %d";   --_G.ITEM_LEVEL in Classic is different
L["Format Breadcrumb Quests Available"] = "사용가능한 퀘스트: %s";    --This type of quest guide the player to a new quest zone. See "Breadcrumb" on https://warcraft.wiki.gg/wiki/Quest#Quest_variations
L["Format Functionality Handled By"] = "이 기능은 다음에 의해 처리됩니다 %s";      --A functionality is provided by [another addon name] (Used in Settings.lua)

--Settings
L["UI"] = "UI";
L["Camera"] = "카메라";
L["Control"] = "입력설정";
L["Gameplay"] = "게임플레이";
L["Accessibility"] = "접근성";

L["Option Enabled"] = "사용함";
L["Option Disabled"] = "사용안함";
L["Move Position"] = "이동";
L["Reset Position"] = "위치 재설정";
L["Drag To Move"] = "마우스 왼쪽 버튼을 클릭하고 드래그하여 창을 이동합니다.";
L["Middle Click To Reset Position"] = "마우스 중간 버튼을 클릭하여 위치를 재설정 합니다.";

L["Quest"] = "퀘스트";
L["Gossip"] = "대화";
L["Theme"] = "테마";
L["Theme Desc"] = "UI의 테마 색상을 선택 합니다.";
L["Theme Brown"] = "갈색";
L["Theme Dark"] = "검정색";
L["Frame Size"] = "프레임 크기";
L["Frame Size Desc"] = "UI 크기를 설정 합니다.\n\n기본값: 중간";
L["Size Extra Small"] = "최소";
L["Size Small"] = "소";
L["Size Medium"] = "중";
L["Size Large"] = "대";
L["Font Size"] = "글자 크기";
L["Font Size Desc"] = "UI의 글자 크기를 설정합니다..\n\n기본값: 12";
L["Frame Orientation"] = "위치";
L["Frame Orientation Desc"] = "화면 왼쪽 or 오른쪽에 UI를 배치";
L["Orientation Left"] = "왼쪽";
L["Orientation Right"] = "오른쪽";
L["Hide UI"] = "UI 숨기기";
L["Hide UI Desc"] = "NPC와 상호작용할 때 게임 UI를 페이드 아웃 합니다.";
L["Hide Unit Names"] = "유닛 이름 숨기기";
L["Hide Unit Names Desc"] = "NPC와 상호 작용할 때 플레이어 및 기타 NPC 이름 숨기기.";
L["Show Copy Text Button"] = "텍스트 복사 버튼 표시";
L["Show Copy Text Button Desc"] = "대화 UI 오른쪽 상단에 텍스트 복사 버튼 표시.\n\n퀘스트, NPC, 아이템 ID와 같은 게임 데이터도 포함됩니다.";
L["Show Quest Type Text"] = "퀘스트 유형 텍스트 표시";
L["Show Quest Type Text Desc"] = "특별한 경우 옵션 오른쪽에 퀘스트 유형을 표시합니다.\n\n낮은 레벨의 퀘스트에는 항상 라벨이 붙습니다.";
L["Show NPC Name On Page"] = "NPC 이름 표시";
L["Show NPC Name On Page Desc"] = "페이지에 NPC 이름을 표시합니다.";
L["Show Warband Completed Quest"] = "전투부대 완료 퀘스트";
L["Show Warband Completed Quest Desc"] = "이전에 다른 캐릭터에서 현재 퀘스트를 완료한 적이 있는 경우 퀘스트 세부 정보 하단에 메모를 표시합니다";
L["Simplify Currency Rewards"] = "보상 금액 간소화";
L["Simplify Currency Rewards Desc"] = "보상 금액에는 작은 아이콘을 사용하고 이름은 생략합니다.";
L["Mark Highest Sell Price"] = "최고 판매 가격 표시";
L["Mark Highest Sell Price Desc"] = "보상을 선택할 때 판매 가격이 가장 높은 품목을 보여줍니다.";
L["Use Blizzard Tooltip"] = "블리자드 툴팁 사용";
L["Use Blizzard Tooltip Desc"] = "퀘스트 보상 버튼에는 특별 툴팁 대신 블리자드 툴팁을 사용하세요.";
L["Roleplaying"] = GDAPI_REALMTYPE_RP or "롤플레잉";
L["Use RP Name In Dialogues"] = "대화 중 RP 이름 사용";
L["Use RP Name In Dialogues Desc"] = "대화 텍스트에서 캐릭터의 이름을 RP 이름으로 대체합니다.";

L["Camera Movement"] = "카메라 이동";
L["Camera Movement Off"] = "끄기";
L["Camera Movement Zoom In"] = "확대";
L["Camera Movement Horizontal"] = "가로";
L["Maintain Camera Position"] = "카메라 위치 유지";
L["Maintain Camera Position Desc"] = "NPC 상호작용이 종료된 후 잠시 카메라 위치를 유지합니다.\n\n이 옵션을 활성화하면 대화 상자 간의 지연으로 인한 카메라의 갑작스러운 움직임이 줄어듭니다.";
L["Change FOV"] = "시각 변화";
L["Change FOV Desc"] = "카메라의 시야를 축소하여 NPC에 더 가깝게 확대합니다.";
L["Disable Camera Movement Instance"] = "인스턴스에서 사용안함";
L["Disable Camera Movement Instance Desc"] = "던전이나 레이드 중에는 카메라 이동을 비활성화합니다.";
L["Maintain Offset While Mounted"] = "탑승 중 오프셋 유지";
L["Maintain Offset While Mounted Desc"] = "탑승 상태에서 화면에서 캐릭터의 위치를 유지하려고 시도합니다.\n\n이 옵션을 활성화하면 대형 탈것의 수평 오프셋이 과도하게 적용될 수 있습니다.";

L["Input Device"] = "입력 장치";
L["Input Device Desc"] = "단축키 아이콘과 UI 레이아웃에 영향을 미칩니다.";
L["Input Device KBM"] = "키보드/마우스";
L["Input Device Xbox"] = "Xbox";
L["Input Device Xbox Tooltip"] = "확인 버튼: [KEY:XBOX:PAD1]\n취소 버튼: [KEY:XBOX:PAD2]";
L["Input Device PlayStation"] = "PlayStation";
L["Input Device PlayStation Tooltip"] = "확인 버튼: [KEY:PS:PAD1]\n취소 버튼: [KEY:PS:PAD2]";
L["Input Device Switch"] = "Switch";
L["Input Device Switch Tooltip"] = "확인 버튼: [KEY:SWITCH:PAD1]\n취소 버튼: [KEY:SWITCH:PAD2]";
L["Primary Control Key"] = "확인 버튼";
L["Primary Control Key Desc"] = "이 버튼를 눌러 퀘스트 수락과 같은 첫 번째 사용 가능한 옵션을 선택합니다."
L["Press Button To Scroll Down"] = "버튼을 눌러 아래로 스크롤합니다";
L["Press Button To Scroll Down Desc"] = "콘텐츠가 뷰포트보다 높은 경우 확인 버튼을 누르면 퀘스트를 수락하는 대신 페이지가 아래로 스크롤됩니다.";
L["Right Click To Close UI"] = "마우스 오른쪽 버튼을 클릭하여 UI 닫기";
L["Right Click To Close UI Desc"] = "대화 UI를 마우스 오른쪽 버튼으로 클릭하여 닫습니다.";
L["Experimental Features"] = "실험성";
L["Emulate Swipe"] = "모의 슬라이딩 동작";
L["Emulate Swipe Desc"] = "창을 클릭하고 드래그하여 대화 UI를 위아래로 스크롤합니다.";
L["Mobile Device Mode"] = "모바일 장치 모드";
L["Mobile Device Mode Desc"] = "실험 특징:\n\nUI 및 글꼴 크기를 늘려 작은 화면 장치에서 텍스트를 읽을 수 있도록 합니다.";
L["Mobile Device Mode Override Option"] = "이 옵션은 현재 제어에서 \"모바일 장치 모드\"를 활성화했기 때문에 적용되지 않습니다.";

L["Key Space"] = "스페이스";
L["Key Interact"] = "상호작용";
L["Cannot Use Key Combination"] = "키 조합은 지원되지 않습니다.";
L["Interact Key Not Set"] = "[KEY:PC:INVALID] 상호 작용 키를 설정하지 않았습니다."
L["Use Default Control Key Alert"] = "계속 [KEY:PC:SPACE]를 확인 버튼으로 사용합니다.";
L["Key Disabled"] = "비활성화";
L["Key Disabled Tooltip"] = "확인 버튼이 비활성화되었습니다.\n\n키를 눌러 퀘스트를 수락할 수 없습니다.";

L["Auto Quest Popup"] = "퀘스트 자동 팝업";
L["Auto Quest Popup Desc"] = "아이템을 집어 들거나 영역을 입력하여 새로운 퀘스트가 자동으로 트리거되면 퀘스트 세부 정보가 표시되지 않고 먼저 팝업에 퀘스트가 표시됩니다.\n\n로그인 시 트리거된 퀘스트가 기준을 충족하지 못할 수 있습니다.";
L["Popup Position"] = "팝업 위치";    --Pop-up window position
L["Widget Is Docked Generic"] = "이 위젯은 다른 팝업과 연결되어 있습니다.";   --Indicate a window is docked with other pop-up windows
L["Widget Is Docked Named"] = "%s이(가) 다른 팝업과 연결되어 있습니다.";
L["Quest Item Display"] = "퀘스트 아이템 표시";
L["Quest Item Display Desc"] = "퀘스트 항목의 설명을 자동으로 표시하고 가방을 열지 않고도 사용할 수 있도록 합니다.";
L["Quest Item Display Hide Seen"] = "표시된 아이템 무시";
L["Quest Item Display Hide Seen Desc"] = "캐릭터가 발견한 아이템은 무시합니다.";
L["Quest Item Display Await World Map"] = " 월드맵을 기다립니다.";
L["Quest Item Display Await World Map Desc"] = "월드맵를 열면 퀘스트 항목 표시를 일시적으로 숨기고 자동 닫기 타이머를 일시 중지합니다.";
L["Quest Item Display Reset Position Desc"] = "창의 위치를 재설정합니다.";
L["Auto Select"] = "자동 선택";
L["Auto Select Gossip"] = "자동 선택 옵션";
L["Auto Select Gossip Desc"] = "특정 NPC와 상호 작용할 때 자동으로 최상의 대화 옵션을 선택합니다.";
L["Force Gossip"] = "대화 강조";
L["Force Gossip Desc"] = "기본적으로 게임은 대화 상자를 표시하지 않고 첫 번째 옵션을 자동으로 선택하는 경우가 있습니다. 대화 강조를 활성화하면 대화가 표시됩니다.";
L["Nameplate Dialog"] = "이름표에 대화 표시";
L["Nameplate Dialog Desc"] = "선택의 여지가 없는 경우 NPC 명판에 대화를 표시합니다.\n\n이 옵션은 CVar \"SoftTarget Nameplate Interact\"을 수정합니다.";

L["TTS"] = TEXT_TO_SPEECH or "텍스트 음성 변환";
L["TTS Desc"] = "UI 왼쪽 상단의 버튼을 클릭하여 대화 텍스트를 큰 소리로 읽습니다.";
L["TTS Use Hotkey"] = "단축키 사용";
L["TTS Use Hotkey Desc"] = "눌러 읽기를 시작하거나 중지합니다:";
L["TTS Use Hotkey Tooltip PC"] = "[KEY:PC:R]";
L["TTS Use Hotkey Tooltip Xbox"] = "[KEY:XBOX:LT]";
L["TTS Use Hotkey Tooltip PlayStation"] = "[KEY:PS:LT]";
L["TTS Use Hotkey Tooltip Switch"] = "[KEY:SWITCH:LT]";
L["TTS Auto Play"] = "자동 재생";
L["TTS Auto Play Desc"] = "대화 텍스트 자동 재생.";
L["TTS Skip Recent"] = "최근 읽은 텍스트 건너뛰기";
L["TTS Skip Recent Desc"] = "최근에 읽은 텍스트를 건너뛸 수 있습니다.";
L["TTS Auto Stop"] = "떠나기시 중지";
L["TTS Auto Stop Desc"] = "NPC를 떠날 때 읽기를 중단합니다.";
L["TTS Stop On New"] = "새 대화 중지";
L["TTS Stop On New Desc"] = "다른 대화 상자를 보기 시작하면 이전 읽기를 중지합니다.";
L["TTS Voice Male"] = "남성 목소리";
L["TTS Voice Male Desc"] = "남성 캐릭터와 상호작용할 때 이 목소리를 사용하세요:";
L["TTS Voice Female"] = "여성 목소리";
L["TTS Voice Female Desc"] = "여성 캐릭터와 상호작용할 때 이 목소리를 사용하세요:";
L["TTS Use Narrator"] = "내레이터";
L["TTS Use Narrator Desc"] = "다른 음성을 사용하여 NPC 이름, 퀘스트 제목, 목표 및 <> 괄호 안의 모든 텍스트를 읽습니다.";
L["TTS Voice Narrator"] = "목소리";
L["TTS Voice Narrator Desc"] = "내레이션에 이 음성을 사용합니다:";
L["TTS Volume"] = "볼륨";
L["TTS Volume Desc"] = "음성 볼륨을 조정합니다.";
L["TTS Rate"] = "음성 속도";
L["TTS Rate Desc"] = "음성 속도를 조정합니다.";
L["TTS Include Content"] = "콘텐츠 포함";
L["TTS Content NPC Name"] = "NPC 이름";
L["TTS Content Quest Name"] = "퀘스트 제목";
L["TTS Content Objective"] = "퀘스트 목표";

--Tutorial
L["Tutorial Settings Hotkey"] = "[KEY:PC:F1]을 눌러 설정을 전환합니다";     --Shown when interacting with an NPC with this addon for the first time
L["Tutorial Settings Hotkey Console"] = "[KEY:PC:F1] 또는 [KEY:CONSOLE:MENU]를 눌러 설정을 전환합니다";   --Use this if gamepad enabled
L["Instruction Open Settings"] = "설정을 열려면 NPC와 상호 작용하는 동안 [KEY:PC:F1]을 누릅니다.";    --Used in Game Menu - AddOns
L["Instruction Open Settings Console"] = "설정을 열려면 NPC와 상호 작용하는 동안 [KEY:PC:F1] 또는 [KEY:CONSOLE:MENU]를 누릅니다.";


--DO NOT TRANSLATE
L["Abbrev Breakpoint 1000"] = "천";     --1,000 = 1K
L["Abbrev Breakpoint 10000"] = "만";    --Reserved for Asian languages that have words for 10,000
L["Match Stat Armor"] = "방어도 ([,%d%.]+)";
L["Match Stat Stamina"] = " 체력 %+([,%d%.]+)";
L["Match Stat Strengh"] = "힘 %+([,%d%.]+)";
L["Match Stat Agility"] = "민첩성 %+([,%d%.]+)";
L["Match Stat Intellect"] = "지능 %+([,%d%.]+)";
L["Match Stat Spirit"] = "정신력 %+([,%d%.]+)";
L["Match Stat DPS"] = "초당 공격력 ([,%d%.]+)";

L["Show Answer"] = "정답을 표시합니다.";
L["Quest Failed Pattern"] = "제거하십시오.$";
L["AutoCompleteQuest HallowsEnd"] = "사탕 바구니";     --Quest:28981

--Asking for Directions-- (match the name to replace gossip icon)
L["Pin Auction House"] = "경매장";
L["Pin Bank"] = "은행";
L["Pin Barber"] = "미용실";
L["Pin Battle Pet Trainer"] = "전투 애완동물 전문가";
L["Pin Crafting Orders"] = "주문 제작";
L["Pin Flight Master"] = "비행 조련사";
L["Pin Great Vault"] = "위대한 금고";
L["Pin Inn"] = "여관";
L["Pin Item Upgrades"] = "아이템 강화";
L["Pin Mailbox"] = "우체통";
L["Pin Other Continents"] = "다른 대륙";
L["Pin POI"] = "주요 관심 지점";
L["Pin Profession Trainer"] = "기술 전문가";
L["Pin Rostrum"] = "변신 강단";
L["Pin Stable Master"] = "야수 관리인";
L["Pin Trading Post"] = "교역소";