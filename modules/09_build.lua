local function BuildGui()
    if not WindUI then return end
    R.guiSyncFns = {}
    local toggleKey = nil
    pcall(function() toggleKey = Enum.KeyCode[S.guiKey] end)
    local okW, Window = pcall(function()
        return WindUI:CreateWindow({
        Title = "discord@kurudojindegomen",
        Author = "Murderers vs Sheriffs 2",
        Icon = "crosshair",
        Folder = "MVS2",
        Size = UDim2.fromOffset(600, 460),
        MinSize = Vector2.new(520, 360),
        MaxSize = Vector2.new(900, 650),
        Theme = S.theme,
        ToggleKey = toggleKey,
        HideSearchBar = false,
        NewElements = true,
        Topbar = { Height = 44, ButtonsType = "Default" },
        OpenButton = {
            Title = "MVS2",
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 2,
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            Scale = 0.5,
        },
        })
    end)
    if not okW then Window = nil end
    if not Window then return end
    R.windWindow = Window
    R.guiOpen = true
    pcall(function() Window:OnOpen(function() R.guiOpen = true end) end)
    pcall(function() Window:OnClose(function() R.guiOpen = false end) end)
    if R.touchOnly then
        pcall(function() Window:Close() end)
        R.guiOpen = false
    end
    pcall(function() Window:Tag({ Title = "v23", Icon = "flame", Color = Color3.fromHex("#1c1c1c"), Border = true }) end)
    local function Tog(sec, title, desc, key, cb)
        local el = sec:Toggle({ Title = title, Desc = desc, Value = S[key], Callback = function(v)
            S[key] = v
            if cb then cb(v) end
        end })
        R.guiSyncFns[#R.guiSyncFns + 1] = function() if el and el.Set then pcall(function() el:Set(S[key], false) end) end end
        return el
    end
    local function Sli(sec, title, desc, key, min, max, step, cb)
        local el = sec:Slider({ Title = title, Desc = desc, Step = step, Value = { Min = min, Max = max, Default = S[key] }, Callback = function(v)
            S[key] = v
            if cb then cb(v) end
        end })
        R.guiSyncFns[#R.guiSyncFns + 1] = function() if el and el.Set then pcall(function() el:Set(S[key]) end) end end
        return el
    end
    local function Drop(sec, title, desc, key, pairsList, cb)
        local dispOf, valOf, values = {}, {}, {}
        for i, pr in ipairs(pairsList) do
            values[i] = pr[1]
            dispOf[pr[2]] = pr[1]
            valOf[pr[1]] = pr[2]
        end
        local el = sec:Dropdown({ Title = title, Desc = desc, Values = values, Value = dispOf[S[key]] or values[1], Callback = function(d)
            local v = valOf[d]
            if v ~= nil then
                S[key] = v
                if cb then cb(v) end
            end
        end })
        R.guiSyncFns[#R.guiSyncFns + 1] = function()
            if el then
                local disp = dispOf[S[key]] or values[1]
                if el.Select then pcall(function() el:Select(disp) end)
                elseif el.Set then pcall(function() el:Set(disp) end) end
            end
        end
        return el
    end
    local TabSilent = Window:Tab({ Title = "サイレント", Icon = "crosshair", Border = true })
    local TabTrig = Window:Tab({ Title = "トリガー", Icon = "zap", Border = true })
    local TabESP = Window:Tab({ Title = "ESP", Icon = "eye", Border = true })
    local TabSys = Window:Tab({ Title = "設定", Icon = "settings", Border = true })
    do
        local sec = TabSilent:Section({ Title = "サイレントエイム" })
        Tog(sec, "有効", "カメラを動かさず弾道だけを敵へ曲げる", "silent", function(v) if v then InstallHooks() end end)
        Tog(sec, "Mouse.Hit / Target 曲げ", "ゲームがマウス座標を読む経路を書き換える（回転は保持）", "silentMouse", function(v) if v then InstallHooks() end end)
        Tog(sec, "Raycast 系 曲げ", "Workspace のレイ判定の向きを書き換える", "silentRay", function(v) if v then InstallHooks() end end)
        Tog(sec, "カメラレイ曲げ", "Camera の ScreenPointToRay 等の向きを書き換える", "silentCamRay", function(v) if v then InstallHooks() end end)
        Tog(sec, "射撃中のみ曲げる", "撃っていない間は照準データを素通しする", "fireGate")
        local sec2 = TabSilent:Section({ Title = "ターゲット" })
        Drop(sec2, "狙う部位", "最も近い部位は大きい部位を少し優先して外しを減らす", "targetMode", { { "最も近い", "Closest" }, { "頭", "Head" }, { "胴体", "Torso" } })
        Drop(sec2, "優先度", "複数いる時の選び方。体力は瀕死を優先", "priority", { { "画面", "Screen" }, { "距離", "Distance" }, { "体力", "Health" } })
        Sli(sec2, "FOV", "この円の中の敵だけを狙う（px）", "fov", 40, 400, 5)
        Sli(sec2, "最大距離", "これより遠い敵は狙わない（m）", "maxDist", 100, 1200, 25)
        Sli(sec2, "命中率", "100 未満では一定割合で曲げない（%）", "hitChance", 10, 100, 5)
        Sli(sec2, "最大偏向角", "カメラ向きから大きく外れた射撃は曲げない（0=無制限）", "maxBend", 0, 120, 5)
        Tog(sec2, "壁チェック", "壁の向こうの敵は狙わない（自分のレイは曲げ対象外）", "wallCheck")
        Tog(sec2, "チームチェック", "味方を狙わない（チーム→色の順で判定）", "teamCheck")
        Tog(sec2, "スティッキー", "一度狙った敵を少し優先し続ける", "sticky")
        Tog(sec2, "保護チェック", "スポーン保護（フォースフィールド）中の敵を狙わない", "ffCheck")
        local sec3 = TabSilent:Section({ Title = "予測" })
        Tog(sec3, "予測", "敵の移動（速度＋加速度＋空中落下）から着弾位置を先読みする", "prediction")
        Tog(sec3, "予測位置で選定", "候補の選定も現在位置ではなく予測位置の画面距離で行う", "predSelect")
        Tog(sec3, "空中は胴体優先", "ジャンプ・落下中の敵は頭より胴体を優先して外しを減らす", "airTorso")
        Tog(sec3, "加重フィット", "直近の動きを重く見て、敵の方向転換への追従と予測の安定を上げる", "fitRecent")
        Tog(sec3, "表面クランプ", "狙う点が部位の外へ出ないよう表面に収めて外しを減らす", "partSurf")
        Sli(sec3, "予測量", "基本の先読み時間（秒）", "predAmount", 0, 0.3, 0.005)
        Tog(sec3, "Ping 補正", "自分の Ping 分だけ予測を自動で伸ばす", "pingComp")
        Tog(sec3, "リゾルバ", "敵の速度が急変したフレームは予測を抑え、ずらし・瞬間移動に外れにくくする", "resolver")
        Sli(sec3, "ヒット位置ばらつき", "狙う点を部位の中で少しばらつかせる（%）", "aimJitter", 0, 50, 1)
        Drop(sec3, "武器種別", "自動は装備中の武器で判定。予測の飛行時間が変わる", "weaponMode", { { "自動", "Auto" }, { "刀", "Knife" }, { "銃", "Gun" } })
        Sli(sec3, "投げ速度", "刀の投げの速さ（studs/秒）。実測に合わせて調整", "knifeSpeed", 60, 300, 5)
        Sli(sec3, "投げ落下補正", "投げの放物線落下をどれだけ上向きに補正するか（%）", "knifeDrop", 0, 100, 5)
        Sli(sec3, "銃の到達時間", "銃弾の到達遅れとして予測に加える秒数", "gunTravel", 0, 0.15, 0.005)
        local sec4 = TabSilent:Section({ Title = "表示" })
        Tog(sec4, "FOV 円", "有効範囲を画面に表示する", "showFov")
        Tog(sec4, "ターゲット線", "狙っている敵へ線を表示する", "showLine")
    end
    do
        local sec = TabTrig:Section({ Title = "トリガーボット" })
        Tog(sec, "有効", "狙った敵が確定したら自動で攻撃する。サイレント併用が前提", "trigger")
        Tog(sec, "全員オート", "画面に写った敵全員を順番に自動で撃つ。FOV・距離の制限なし（発動遅延も無効）", "multiFire")
        Tog(sec, "即時発射", "敵を認識した瞬間に撃つ。発動遅延を無効化し、認識したフレームで即発射する（敵・生存・壁・保護のチェックは維持）", "instantFire")
        Sli(sec, "発動遅延", "同じ敵を狙い続けてから撃つまでの時間（ms）。即時発射がオンの時は効かない", "triggerDelay", 0, 600, 10)
        Sli(sec, "クールダウン", "発動間隔の下限。武器の実クールダウンに合わせる。全員オートの回転速度もこれ", "triggerCooldown", 10, 1500, 10)
        Sli(sec, "範囲（銃・投げ）", "この距離まで自動発動する（m）", "triggerRange", 30, 600, 10)
        Sli(sec, "斬撃の範囲（刀）", "刀の接近攻撃が届く距離でのみ斬る（m）", "stabRange", 6, 30, 1)
        Tog(sec, "刀の自動投げ", "斬撃範囲の外ではツール内の Throw リモート→キー送信の順で投げる", "triggerThrow")
    end
    do
        local sec = TabESP:Section({ Title = "ESP" })
        Tog(sec, "有効", "敵の情報を壁越しに表示する（外部描画のみ・ゲーム内に何も置かない）", "esp")
        Tog(sec, "ボックス", "体の枠を描く", "espChams")
        Drop(sec, "ボックス形式", "通常は四角、コーナーは四隅だけ", "espBoxStyle", { { "通常", "Box" }, { "コーナー", "Corner" } })
        Tog(sec, "塗りつぶし", "ボックス内を薄く塗る", "espFill")
        Tog(sec, "スケルトン", "骨格の線を描く", "espSkeleton")
        Tog(sec, "スケルトン輪郭", "骨格の下に黒い輪郭を引いて、明るい背景でも骨格を見失わない", "espSkelOutline")
        Drop(sec, "スケルトンの色", "体力=体力で色が変化 / 役割=ボックスと同じ色 / 固定=下で選んだ色", "espSkelMode", { { "体力", "Health" }, { "役割", "Role" }, { "固定", "Custom" } })
        Drop(sec, "スケルトン固定色", "スケルトンの色を「固定」にした時の色", "espSkelCol", { { "赤", "Red" }, { "緑", "Green" }, { "青", "Blue" }, { "紫", "Purple" }, { "白", "White" }, { "橙", "Orange" }, { "水色", "Cyan" }, { "桃", "Pink" } })
        Sli(sec, "スケルトンの太さ", "骨格の線の太さの倍率（距離でも自動で変わる）", "espSkelThick", 1, 3, 1)
        Tog(sec, "関節ドット", "頭・両手・両足の関節に点を表示する", "espSkelJoints")
        Tog(sec, "武器名表示", "距離表示に、敵が装備している武器名も出す", "espWeaponName")
        Tog(sec, "トレーサー", "画面下から敵へ線を引く", "espTracer")
        Tog(sec, "頭ドット", "頭の位置に点を表示する", "espHeadDot")
        Tog(sec, "名前＋武器", "頭上に名前と装備武器（刀/銃）を表示する", "espName")
        Tog(sec, "武器で色分け", "刀持ちは赤、銃持ちは青で表示する", "espRoleColor")
        Tog(sec, "体力バー", "左に体力バーを表示する", "espHealth")
        Tog(sec, "距離", "下に距離と体力を表示する", "espDistance")
        Sli(sec, "ESP 距離上限", "これより遠い敵は表示しない（m）", "espMaxDist", 50, 1500, 25)
        Tog(sec, "画面外の矢印", "画面の外や背後にいる敵を、画面端の矢印で示す", "espArrows")
        Tog(sec, "ターゲット強調", "今狙っている敵を金色＋太枠で表示する", "espTargetCol")
        Tog(sec, "壁越し減光", "壁の向こうにいる敵を薄く表示して、見えている敵と見分ける", "espDim")
        Tog(sec, "ボックス輪郭", "ボックスの外側に黒い輪郭を描いて視認性を上げる", "espOutline")
        Tog(sec, "可視で色分け", "見えている敵は通常色、壁越しの敵はくすんだ色で表示する", "espVisCol")
        Tog(sec, "距離フェード", "遠い敵ほど少し薄く表示して近くの敵を目立たせる", "espDistFade")
        Tog(sec, "体力バーの滑らかさ", "体力バーの変化を滑らかにアニメーションする", "espHpSmooth")
        Drop(sec, "ESP の色", "武器色分けがオフの時の色", "espColor", { { "赤", "Red" }, { "緑", "Green" }, { "青", "Blue" }, { "紫", "Purple" }, { "白", "White" }, { "橙", "Orange" }, { "水色", "Cyan" }, { "桃", "Pink" } })
    end
    do
        local sec = TabSys:Section({ Title = "状態" })
        R.statusPara = sec:Paragraph({ Title = "状態", Desc = "初期化中" })
        local secF = TabSys:Section({ Title = "FPS ブースト" })
        R.fpsPara = secF:Paragraph({ Title = "現在の FPS", Desc = "計測中" })
        Tog(secF, "FPS ブースト", "影・ポストエフェクト・パーティクル・地形装飾・フォグを切り、画質を最速にする", "fpsBoost", function() FpsApply() end)
        Tog(secF, "超軽量（材質フラット）", "全パーツの材質をフラット化する（キャラのパーツは除外。床の摩擦感が変わることがある）。FPS ブーストと併用する", "fpsUltra", function() FpsApply() end)
        Tog(secF, "FPS 上限解除", "FPS キャップを 1000 に引き上げる（実測は端末性能と画面リフレッシュが上限）", "fpsUnlock", function() FpsCapApply() end)
        Tog(secF, "FPS を画面に表示", "画面左上に現在の FPS を常時表示する", "showFpsHud")
        local secS = TabSys:Section({ Title = "スピンボット" })
        Tog(secS, "スピンボット", "自分の体を高速で回転させ続け、敵の狙いを外れさせる", "spinBot")
        Sli(secS, "回転速度", "1秒あたりの回転角度（度）", "spinSpeed", 180, 3600, 60)
        local sec2 = TabSys:Section({ Title = "テーマ・キー" })
        Drop(sec2, "テーマ", "WindUI の配色テーマ", "theme", { { "Dark", "Dark" }, { "Indigo", "Indigo" }, { "Emerald", "Emerald" }, { "Rose", "Rose" }, { "Amber", "Amber" }, { "Sky", "Sky" }, { "Midnight", "Midnight" }, { "Violet", "Violet" } }, function(v)
            pcall(function() WindUI:SetTheme(v) end)
        end)
        Drop(sec2, "GUI 開閉キー", "Insert は常に併用できる", "guiKey", { { "右Shift", "RightShift" }, { "Insert", "Insert" }, { "左Alt", "LeftAlt" }, { "右Ctrl", "RightControl" } }, function(v)
            pcall(function()
                local kc = Enum.KeyCode[v]
                if kc and Window.SetToggleKey then Window:SetToggleKey(kc) end
            end)
        end)
        local sec3 = TabSys:Section({ Title = "設定ファイル" })
        sec3:Button({ Title = "設定を保存", Desc = "今の設定をファイルに保存する（値は自動で検証される）", Callback = function() SaveConfig() end })
        sec3:Button({ Title = "設定を読込", Desc = "保存した設定を読み込む", Callback = function() LoadConfig(false) end })
        sec3:Button({ Title = "推奨プリセット", Desc = "サイレント＋ESP の推奨構成を一括で適用する", Callback = function() ApplyPreset() end })
        sec3:Button({ Title = "初期設定に戻す", Desc = "全ての設定を初期値に戻す", Callback = function() ResetConfig() end })
        sec3:Button({ Title = "アンロード", Desc = "全機能を止めて GUI を消す（フックは無効化される）", Color = Color3.fromHex("#ff4830"), Callback = function() CTL.Unload() end })
    end
    pcall(function() Window:SelectTab(1) end)
end
Conn(UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.Touch then R.touchOnly = true end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        R.inputs[input] = true
        R.inputDown = true
        R.inputStamp = os.clock()
    elseif input.UserInputType == Enum.UserInputType.Touch then
        if not R.touchOnly or gpe then
            R.inputs[input] = true
            R.inputDown = true
            R.inputStamp = os.clock()
        end
    end
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert and R.windWindow then
        pcall(function()
            if R.guiOpen then R.windWindow:Close() else R.windWindow:Open() end
        end)
    end
end))
Conn(UserInputService.InputEnded:Connect(function(input)
    if R.inputs[input] then
        R.inputs[input] = nil
        if not next(R.inputs) then R.inputDown = false end
    end
end))
