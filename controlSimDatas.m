classdef controlSimDatas < handle
    % このクラスは、シミュレーション環境から取得したデータを管理し、
    % 各種パラメータやログを集計、解析するためのクラスです。
    % 主にEgo（自車）とActor（他車）の挙動データや、衝突判定結果、最終評価値（PET、CriticalSpeed等）を算出します。
    
    properties
        rrSim               % シミュレーション環境（Simulink Scenario Simulationオブジェクトなど）の参照
        
        simTimes = 0;       % 現在のシミュレーション実行回数（試行番号や繰り返し回数）
        
        inputTable          % 入力パラメータが記載されたテーブル（CSVなどのファイルをreadtableで読み込む）
        
        % ---------------------------
        % 各種シミュレーションパラメータ（入力テーブルから設定）
        % ---------------------------
        maxSimulationTimes  % 同一条件下でのシミュレーション回数（複数回実施する場合の試行回数）
        value_dis           % 初期状態におけるEgoとActor間の距離（メートル単位など、後の衝突距離計算に利用）
        value_egoInitSpeed  % Egoの初期速度（シミュレーション開始時の速度）
        value_egoTargetSpeed% Egoが変速後に目標とする速度
        value_egoAcc        % Egoの加速度（正または負の値、加減速の割合）
        value_actInitSpeed  % Actorの初期速度（シミュレーション開始時の他車速度）
        value_actReactionTime% Actorが速度変更を始めるまでの反応時間（ミリ秒または秒）
        value_actTargetSpeed% Actorが変速後に目標とする速度
        value_actAcc        % Actorの加速度
        
        % ---------------------------
        % シミュレーション対象のオブジェクト（EgoとActor）
        % ---------------------------
        ego                 % Egoオブジェクト（Simulink内の自車シミュレーション対象）
        act                 % Actorオブジェクト（Simulink内の他車シミュレーション対象）
        
        % ---------------------------
        % リアルタイムデータ構造体（シミュレーション実行中に毎ステップ更新）
        % ---------------------------
        realtimeData = struct('time', [], ...        % 現在時刻（シミュレーション時刻）
                              'egoAngVel', [], ...   % Egoの角速度（通常Z軸回りの回転角度、度またはラジアン）
                              'egoVel', [], ...      % Egoの速度ベクトル（[vx,vy,vz]など）
                              'egoSpeed', [] , ...    % Egoの速度（スカラー、normで計算）
                              'egoSpeedHor', [], ... % Egoの水平速度成分（角度に基づく分解）
                              'egoSpeedVer', [], ... % Egoの鉛直速度成分
                              'egoAcc', [], ...      % Egoの加速度（スカラー値、前回との差分より算出）
                              'egoAccHor', [], ...   % Egoの水平加速度成分（ミリ秒単位換算）
                              'egoAccVer', [], ...   % Egoの鉛直加速度成分
                              'actVel', [], ...      % Actorの速度ベクトル
                              'actSpeed', [] , ...    % Actorの速度（スカラー）
                              'actAcc', [], ...      % Actorの加速度
                              'dis', [], ...         % EgoとActor間の距離（補正値rを考慮した値）
                              'isCollision', []);    % 現在の衝突状態（シミュレーション中の判定結果）
                          
        % ---------------------------
        % 直前の状態を保持する構造体（速度や時刻など、微分計算の基準となる値）
        % ---------------------------
        previousData = struct('time', [], ...
                              'egoAngVel', [], ...
                              'egoSpeed', [], ...
                              'egoSpeedHor', [], ...
                              'egoSpeedVer', [], ...
                              'actSpeed', []);
                          
        % ---------------------------
        % 最終的なシミュレーション結果をまとめる構造体
        % ---------------------------
        resultsStruct = struct('times', [], ...          % シミュレーション実行回数
                               'actRea', [], ...         % Actorの反応時間（必要に応じて調整済みの値）
                               'egoAcc', [], ...         % Egoの設定された加速度
                               'actSpeed', [], ...       % Actorの初期速度
                               'actAcc', [], ...         % Actorの加速度
                               'disInit', [], ...        % 初期状態のEgoとActorの距離
                               'DTC', [], ...            % Distance To Collision：シミュレーション中に記録された最小距離
                               'PET', [], ...            % Post Encroachment Time：停止完了時刻の差分
                               'CriticalSpeed', [], ...  % 衝突回避のための臨界速度の算出値
                               'PETcondition', [], ...   % PETに基づく安全性判定（risky/safety）
                               'CScondition', [], ...    % CriticalSpeedに基づく安全性判定（risky/safety）
                               'isCollision', []);       % 衝突判定の最終結果
                           
        % ---------------------------
        % シミュレーションのログデータを保持する構造体（シミュレーション終了後に作成）
        % ---------------------------
        dataLog = struct('isCollision', [], ...     % 衝突結果（Success/Failed）
                         'InitDis', [], ...         % シミュレーション開始時の距離
                         'SimulationTime', [] , ...  % シミュレーションの総実行時間（ミリ秒）
                         'times', [], ...           % 試行回数等の識別情報
                         'Results', []);            % 各時刻ごとの詳細なログ（配列の構造体）
                     
        logLength           % ログデータのサンプル数（時系列データの長さ）
        
        disMin              % シミュレーション中に記録されたEgoとActor間の最小距離（DTC：Distance To Collision）
        
        % ---------------------------
        % 衝突判定や完了状態を管理するフラグ
        % ---------------------------
		isCollision = '-';        % 衝突判定の結果。初期状態は'-'（未判定）とする。
        isEgoCompleted      % Egoの動作（停止など）が完了したかどうかのフラグ（true/false）
        isActCompleted      % Actorの動作（停止など）が完了したかどうかのフラグ（true/false）
        isEgoCompletedTime = 999999; % Egoの停止完了時刻。初期値は大きな値で初期化
        isActCompletedTime = 999999; % Actorの停止完了時刻。初期値は大きな値で初期化

        % ---------------------------
        % 物理定数などの設定（シミュレーション評価で利用）
        % ---------------------------
        r = 5.88            % 2車両の中心から実際の接触点までの距離（補正値。車両形状に依存）
        n = 1;              % 利用目的に応じた定数（ここでは特に変化しないので1に設定）
        g = 9.81;           % 重力加速度 [m/s^2]（物理計算に利用）
        f = 0.8;            % 摩擦係数または安全係数（ブレーキ性能などの評価に利用）
        PET                 % PET (Post Encroachment Time：衝突後通過時間) の算出結果
    end
    
    methods
        % -----------------------------------------------------------
        % コンストラクタ
        % シミュレーション環境オブジェクトrrSimを受け取り、プロパティに設定する
        % -----------------------------------------------------------
        function obj = controlSimDatas(rrSim)
            % コンストラクタはシミュレーション環境との接続を確立するために必要なオブジェクトを引数として受け取る
            obj.rrSim = rrSim;
        end

        % -----------------------------------------------------------
        % 入力テーブルをファイルから読み込む関数
        % tableName: 読み込み対象のファイル名（例："inputParams.csv"）
        % -----------------------------------------------------------
        function readTable(obj, tableName)
            % readtable関数を利用して、CSV等のテーブル形式のファイルからパラメータを取得
            obj.inputTable = readtable(tableName);
        end
        

        % -----------------------------------------------------------
        % 入力テーブルからn番目のシミュレーションパラメータを設定する関数
        % n: テーブル内の行番号。各行が別条件・別試行のパラメータを表す
        % -----------------------------------------------------------
        function setInput(obj, n)
            % テーブル内の各列から必要なパラメータを抽出し、クラスプロパティに設定する
            obj.maxSimulationTimes = obj.inputTable.times(n);         % 同一条件下で実施するシミュレーション回数
            obj.value_dis = obj.inputTable.InitDistance(n);             % 初期のEgoとActor間の距離（通常は安全距離として設定）
            obj.value_egoInitSpeed = obj.inputTable.EgoInitSpeed(n);      % Egoの初期速度
            obj.value_egoTargetSpeed = obj.inputTable.EgoTargetSpeed(n);  % Egoの変速後の目標速度
            obj.value_egoAcc = obj.inputTable.EgoAcceleration(n);         % Egoの加速度（シミュレーション上の加速値）
            obj.value_actInitSpeed = obj.inputTable.ActorInitSpeed(n);    % Actorの初期速度
            obj.value_actReactionTime = obj.inputTable.ActorReactionTime(n); % Actorが速度変更を開始するまでの反応時間
            obj.value_actTargetSpeed = obj.inputTable.ActorTargetSpeed(n);   % Actorの変速後の目標速度
            obj.value_actAcc = obj.inputTable.ActorAcceleration(n);       % Actorの加速度
        end

        % -----------------------------------------------------------
        % シミュレーション開始前の初期化処理
        % 各種フラグ、オブジェクト、過去データの初期値をリセットする
        % -----------------------------------------------------------
        function Init(obj)
            % 各種フラグを初期化して、シミュレーション開始前の状態を整えます。
            obj.isEgoCompleted = false;    % Egoの動作完了フラグをリセット（まだ停止していない）
            obj.isActCompleted = false;    % Actorの動作完了フラグをリセット（まだ停止していない）
            obj.ego = [];                  % Egoオブジェクトはまだ取得されていないので空にする
            obj.act = [];                  % Actorオブジェクトも同様に初期化
            obj.isCollision = '-';         % 衝突判定は初期状態では未判定を示すため'-'と設定
            
            % 微分計算用に、前回時刻・速度などの初期値を設定する
            obj.previousData.time = 0;         % シミュレーション開始時刻は0（基準）
            obj.previousData.egoAngVel = 0;      % 初期角速度は0
            obj.previousData.egoSpeedHor = 0;    % 初期水平速度成分は0
            obj.previousData.egoSpeedVer = 0;    % 初期鉛直速度成分は0
            % 初期速度は、入力パラメータから設定した値をそのまま使用
            obj.previousData.egoSpeed = obj.value_egoInitSpeed;
            obj.previousData.actSpeed = obj.value_actInitSpeed;

            obj.PET = 0; % PET（侵入後通過時間）の初期値を0に設定
        end
        
        % -----------------------------------------------------------
        % EgoおよびActorオブジェクトをシミュレーション環境から取得する関数
        % シミュレーション開始直後は対象オブジェクトが生成されていない可能性があるため、取得できるまでループする
        % -----------------------------------------------------------
        function setEgoAndActor(obj)
            % 対象オブジェクトが取得できるまで、短い間隔（0.01秒）で再試行を行う
            while isempty(obj.ego) || isempty(obj.act)
                try
                    % SimulinkのScenarioSimulation.find関数を用いて、各ActorIDに対応するオブジェクトを取得
                    % ActorID=1 をEgo、ActorID=2 をActorとして取得する想定
                    obj.ego = Simulink.ScenarioSimulation.find("ActorSimulation", ActorID=uint64(1));
                    obj.act = Simulink.ScenarioSimulation.find("ActorSimulation", ActorID=uint64(2));
                    pause(0.01);  % 取得に成功した場合も少し待機して、システムの同期を図る
                catch
                    % 取得に失敗した場合も、同様に短い待機後に再試行する
                    pause(0.01);
                end
            end    
        end

        % -----------------------------------------------------------
        % シミュレーション中のリアルタイムデータを更新する関数
        % 各種センサ情報（速度、加速度、角速度、位置情報など）を取得し、必要な計算を行う
        % -----------------------------------------------------------
        function createRealtimeStructs(obj)
            % 現在のシミュレーション時刻を取得（rrSimオブジェクトから直接取得）
            obj.realtimeData.time  = get(obj.rrSim, "SimulationTime");

            % Egoの角速度を取得。ここではgetAttribute関数を使用して、角速度センサ情報を抽出
            obj.realtimeData.egoAngVel = getAttribute(obj.ego, "AngularVelocity");

            % Egoの速度ベクトルを取得し、ベクトルのノルムを計算することでスカラーの速度を求める
            obj.realtimeData.egoVel = getAttribute(obj.ego, "Velocity");
            obj.realtimeData.egoSpeed = norm(obj.realtimeData.egoVel);
            % 取得した角度情報（egoAngVel）を利用して、水平成分（sind）と鉛直成分（cosd）に分解
            obj.realtimeData.egoSpeedHor = obj.realtimeData.egoSpeed * sind(obj.realtimeData.egoAngVel);
            obj.realtimeData.egoSpeedVer = obj.realtimeData.egoSpeed * cosd(obj.realtimeData.egoAngVel);
            % 前回の速度データとの差分を時間差で割ることで、加速度を計算する
            obj.realtimeData.egoAcc = (obj.realtimeData.egoSpeed - obj.previousData.egoSpeed) / ...
                                      (obj.realtimeData.time - obj.previousData.time);
            % 水平成分、鉛直成分それぞれについても、前回との差分から加速度を計算し、ミリ秒換算のために1000倍する
            obj.realtimeData.egoAccHor = (obj.realtimeData.egoSpeedHor - obj.previousData.egoSpeedHor) / ...
                                         (obj.realtimeData.time - obj.previousData.time) * 1000;
            obj.realtimeData.egoAccVer = (obj.realtimeData.egoSpeedVer - obj.previousData.egoSpeedVer) / ...
                                         (obj.realtimeData.time - obj.previousData.time) * 1000;
            
            % 同様に、Actorの速度情報を取得し、速度および加速度を計算
            obj.realtimeData.actVel = getAttribute(obj.act, "Velocity");
            obj.realtimeData.actSpeed = norm(obj.realtimeData.actVel);            
            obj.realtimeData.actAcc = (obj.realtimeData.actSpeed - obj.previousData.actSpeed) / ...
                                      (obj.realtimeData.time - obj.previousData.time);

            % EgoとActorの位置情報（Pose）を取得し、両者の中心位置の差からユークリッド距離を計算
            % ここでは、Poseが4x4の変換行列の場合、第4列（平行移動成分）を抽出して利用
            egoPos = getAttribute(obj.ego, "Pose");  % EgoのPose情報（通常は変換行列）
            actPos = getAttribute(obj.act, "Pose");  % ActorのPose情報
            % 得られた距離から、補正値rを引くことで、実際の接触する可能性のある距離に調整する
            obj.realtimeData.dis = norm(egoPos.Pose(1:3, 4) - actPos.Pose(1:3, 4)) - obj.r;
            
            % 現在の衝突状態（シミュレーション中に外部で更新される値）をリアルタイムデータに反映
            obj.realtimeData.isCollision = obj.isCollision;

            % 現在の各データを「前回データ」として更新。これにより次回の差分計算が正確に行われる
            obj.previousData.time = obj.realtimeData.time;
            obj.previousData.egoSpeed = obj.realtimeData.egoSpeed;
            obj.previousData.actSpeed = obj.realtimeData.actSpeed;
            obj.previousData.egoSpeedHor = obj.realtimeData.egoSpeedHor;
            obj.previousData.egoSpeedVer = obj.realtimeData.egoSpeedVer;
        end

        % -----------------------------------------------------------
        % シミュレーションログから各種データを抽出し、結果ログ構造体(dataLog)を作成する関数
        % シミュレーション終了後に、各時刻ごとの詳細データをまとめ、評価指標(DTC, PETなど)を算出する
        % -----------------------------------------------------------
        function createLogStructs(obj)
            % シミュレーション全体のログを取得。ログにはセンサデータ、タイムスタンプ、診断情報などが含まれる
            simLog = get(obj.rrSim, "SimulationLog");

            % ログから、EgoとActorの速度データを各ActorIDに基づいて抽出
            egoVel = get(simLog, 'Velocity', 'ActorID', 1);
            actVel = get(simLog, 'Velocity', 'ActorID', 2);

            % 同様に、位置情報（Pose）も各Actorごとに抽出
            egoPos = get(simLog, "Pose", "ActorID", 1);
            actPos = get(simLog, "Pose", "ActorID", 2);

            % Egoの角速度（主にZ軸回り）を抽出。角速度は衝突リスクの解析に利用されることもある
            egoAngVel = get(simLog, 'AngularVelocity', 'ActorID', 1);

            % -----------------------------------------------------------
            % 衝突判定処理：Diagnostics情報から"Collision"に関連するメッセージがあるかを調査
            % -----------------------------------------------------------
            collisionMessages = false;         % 初期状態では衝突はないと仮定
            diagnostics = get(simLog, "Diagnostics"); % シミュレーション中に出力された診断メッセージを取得
    
            if ~isempty(diagnostics)  % 診断情報が存在する場合
                % 診断メッセージ内に"Collision"という文字列が含まれていれば、衝突発生と判断
                collisionMessages = contains(string(diagnostics.Message), 'Collision');
            end
    
            if collisionMessages
                obj.isCollision = 'Failed';  % 衝突が発生した場合は"Failed"として記録
            else
                obj.isCollision = 'Success'; % 衝突がなければ"Success"として記録
            end
            
            % ログのサンプル数（時系列データの個数）を取得。以降のループで各サンプルごとに計算を実施
            obj.logLength = length(egoVel);

            % dataLog構造体の基本情報を設定
            obj.dataLog.isCollision = obj.isCollision;         % 最終的な衝突判定結果
            obj.dataLog.InitDis = obj.value_dis;               % シミュレーション開始時のEgoとActorの距離
            % 最終サンプルの時刻（秒単位）をミリ秒に変換してシミュレーション全体の実行時間とする
            obj.dataLog.SimulationTime = egoVel(obj.logLength).Time * 1000;
            % シミュレーション実行回数（条件識別用）も記録
            obj.dataLog.times = obj.simTimes; 
        
            % 各時刻ごとの詳細なデータを、配列形式のResultsに格納する
            for i = 1:obj.logLength 
                % 各サンプルの時刻をミリ秒単位に変換して記録
                obj.dataLog.Results(i).time = egoVel(i).Time * 1000;

                % Egoの角速度（3軸目＝Z軸）の値をラジアンから度に変換して記録
                obj.dataLog.Results(i).egoAngVelLog = rad2deg(egoAngVel(i).AngularVelocity(3));
        
                % Egoの速度ベクトルをそのまま記録するとともに、norm関数でスカラー値の速度を計算
                obj.dataLog.Results(i).egoVel = egoVel(i).Velocity; 
                obj.dataLog.Results(i).egoSpeed = norm(egoVel(i).Velocity);
                % 角度情報を用いて、Egoの水平速度成分と鉛直速度成分を計算
                obj.dataLog.Results(i).egoSpeedHor = obj.dataLog.Results(i).egoSpeed * sind(obj.dataLog.Results(i).egoAngVelLog);
                obj.dataLog.Results(i).egoSpeedVer = obj.dataLog.Results(i).egoSpeed * cosd(obj.dataLog.Results(i).egoAngVelLog);
        
                % 最初のサンプルでは前回との差分が取れないため、加速度は0とする
                if i == 1
                    obj.dataLog.Results(i).egoAcc = 0; 
                    obj.dataLog.Results(i).egoAccHor = 0; 
                    obj.dataLog.Results(i).egoAccVer = 0; 
                else
                    % 前時刻との差分からEgoの加速度（スカラー）、および水平・鉛直加速度を計算
                    obj.dataLog.Results(i).egoAcc = (obj.dataLog.Results(i).egoSpeed - obj.dataLog.Results(i - 1).egoSpeed) ...
                        / (obj.dataLog.Results(i).time - obj.dataLog.Results(i - 1).time) * 1000;
                    obj.dataLog.Results(i).egoAccHor = (obj.dataLog.Results(i).egoSpeedHor - obj.dataLog.Results(i - 1).egoSpeedHor) ...
                        / (obj.dataLog.Results(i).time - obj.dataLog.Results(i - 1).time) * 1000;
                    obj.dataLog.Results(i).egoAccVer = (obj.dataLog.Results(i).egoSpeedVer - obj.dataLog.Results(i - 1).egoSpeedVer) ...
                        / (obj.dataLog.Results(i).time - obj.dataLog.Results(i - 1).time) * 1000;
                end
        
                % Actorの速度および加速度の計算。初回は加速度0、以降は前回との差分から算出
                obj.dataLog.Results(i).actVel = actVel(i).Velocity;
                obj.dataLog.Results(i).actSpeed = norm(actVel(i).Velocity);
                if i == 1
                    obj.dataLog.Results(i).actAcc = 0; 
                else
                    obj.dataLog.Results(i).actAcc = (obj.dataLog.Results(i).actSpeed - obj.dataLog.Results(i - 1).actSpeed) ...
                        / (obj.dataLog.Results(i).time - obj.dataLog.Results(i - 1).time);
                end
                
                % EgoとActorの位置情報から、各時刻における中心間のユークリッド距離を計算
                % ここでは、Poseの第4列（平行移動成分）を用いて計算し、補正値rを引く
                obj.dataLog.Results(i).dis = norm(egoPos(i).Pose(1:3, 4) - actPos(i).Pose(1:3, 4)) - obj.r;

                % 最終サンプルの時刻のみ、衝突判定結果（Success/Failed）を記録し、
                % 途中の時刻はまだ確定していないため'-'で示す
                if i == obj.logLength 
                    obj.dataLog.Results(i).isCollision = obj.isCollision;
                else
                    obj.dataLog.Results(i).isCollision = '-';
                end

                % ---------------------------
                % Egoの動作完了判定
                % 条件：Egoの速度が0になり、かつ直前との速度差分（加速度）が負の場合、
                % 　→ ブレーキがかかり完全停止したと判断
                % ---------------------------
                if obj.dataLog.Results(i).egoSpeed == 0 && obj.dataLog.Results(i).egoAcc < 0
                    obj.isEgoCompleted = true;
                    obj.isEgoCompletedTime = obj.dataLog.Results(i).time;  % 完全停止した時刻を記録
                end

                % ---------------------------
                % Actorの動作完了判定
                % 条件：Actorの速度が非常に小さく（0.001以下）、
                % かつ、加速度が負の場合（徐々に停止している）であり、
                % まだ完了が記録されていなければ、停止完了とみなす
                % その際、PET（Post Encroachment Time）は、Actor停止時刻とEgo停止時刻の差分として計算
                % ---------------------------
                if obj.dataLog.Results(i).actSpeed < 0.001 && obj.dataLog.Results(i).actAcc < 0 && obj.isActCompleted == false
                    obj.isActCompleted = true;
                    obj.isActCompletedTime = obj.dataLog.Results(i).time;
                    obj.PET = obj.isActCompletedTime - obj.isEgoCompletedTime;
                end
                
                % ---------------------------
                % Egoが既に完了している場合、以降の距離データは無効とするため、固定値（999）に設定
                % ---------------------------
                if obj.isEgoCompleted == true
                    obj.dataLog.Results(i).dis = 999;
                end
            end
            % 全時刻のデータから、実際に最小となった距離（DTC: Distance To Collision）を求める
            obj.disMin = min([obj.dataLog.Results.dis]);
        end

        % -----------------------------------------------------------
        % 最終結果をまとめた構造体(resultsStruct)を作成する関数
        % 各種入力パラメータとシミュレーション結果（ログ）から、最終的な評価指標を算出する
        % -----------------------------------------------------------
        function createResultStruct(obj)
            % 入力パラメータおよびシミュレーション結果を、結果構造体に転記する
            obj.resultsStruct.times = obj.simTimes;              % 試行回数
            % Actorの反応時間。mod関数で調整する理由は、単位変換やフォーマットの統一のため
            obj.resultsStruct.actRea = mod(obj.value_actReactionTime, 100);
            obj.resultsStruct.egoAcc = obj.value_egoAcc;           % Egoの加速度（入力パラメータ）
            obj.resultsStruct.actSpeed = obj.value_actInitSpeed;     % Actorの初期速度
            obj.resultsStruct.actAcc = obj.value_actAcc;           % Actorの加速度
            obj.resultsStruct.disInit = obj.value_dis;             % 初期のEgoとActor間の距離
            obj.resultsStruct.isCollision = obj.isCollision;       % 衝突判定の最終結果
            obj.resultsStruct.DTC = obj.disMin;                    % シミュレーション中の最小距離（DTC）
            obj.resultsStruct.PET = obj.PET;                       % PET (Post Encroachment Time)
            % CriticalSpeedの計算：PET、重力加速度、摩擦係数を用いて、車両の安全な減速距離などから臨界速度を算出
            % ※単位換算のために1000で割っている（PETがミリ秒の場合など）
            obj.resultsStruct.CriticalSpeed = obj.PET * 2 * obj.g * obj.f / 1000;

            % ---------------------------
            % PETに基づく安全性の判定
            % PETが3000ミリ秒以下の場合はリスクが高い（"risky"）、それ以上は安全（"safety"）と判断
            % ---------------------------
            if obj.PET <= 3000
                obj.resultsStruct.PETcondition = 'risky';
            else
                obj.resultsStruct.PETcondition = 'safety';
            end

            % ---------------------------
            % CriticalSpeedに基づく安全性の判定
            % CriticalSpeedが40未満の場合、危険（"risky"）、40以上なら安全（"safety"）と判断
            % ---------------------------
            if obj.resultsStruct.CriticalSpeed < 40
                obj.resultsStruct.CScondition = 'risky';
            else
                obj.resultsStruct.CScondition = 'safety';
            end
        end

    end
end