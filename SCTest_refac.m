try  
    email = 'tier4.jp'; % ログイン用メールアドレス
    password = 'tier4'; % ログイン用のパスワードを入力
    
    % その他の必要な情報
    dcaseID = 'ZOkeBMC80fOHeAkjkswqBu8hveyXxdtQSJxhDEr4qUw_';
    partsID = 'Parts_qypn1wir';
    userList = {'uaw_rebPBN_g9oDNrRmD0vs71jRfWeZ2HqZ_lu8idLE_'};

	% dcaseとの通信を確率
    dcase = dcaseCommunication(email,password,dcaseID,partsID,userList);
    
    % 入出力ファイル名の定義
    inputTableName = 'inputTest.csv';
    realTimeDataJsonName = 'realtime.json';
    logDataJsonName = 'result.json';
    simpleResultsJsonName = 'resultSimple.json';
    simpleResultCsvName = 'TestResult.csv';

    %入力テーブルの格納
    inputTable = readtable(inputTableName);

    % 作業プロジェクト
    rrproj = "/home/furuuchi/ドキュメント/GitHub/Roadrunner";
    % roadrunnerを起動
    rrApp=roadrunner(rrproj,InstallationFolder="/usr/local/RoadRunner_R2024b/bin/glnxa64");
    % シナリオ読み込み、変化に注意。
    scenarioFile="/home/furuuchi/ドキュメント/GitHub/Roadrunner/Scenarios/Testcase_pre2.rrscenario";
    % シナリオを指定して開く
    openScenario(rrApp,scenarioFile);
    rrSim=createSimulation(rrApp);

    %シミュレーション設定
    set(rrSim,"Logging","on");%シミュレーションのログを取れるようにする
    set(rrSim,PacerStatus="On");%シミュレーションの倍速を許可する

    maxSimulationTimeSec = 15;%シミュレーションの最大時間
    StepSize = 0.02;%何秒ごとにシミュレーションを行うか
    simulationPace = 1;%何倍の速度で行うか
    
    %上記3つのパラメータをシミュレーションに設定
    set(rrSim,'MaxSimulationTime',maxSimulationTimeSec);
    set(rrSim,'StepSize',StepSize);
    set(rrSim,SimulationPace=simulationPace)    
    
    % シミュレーションのパラメータの定義
    dis = "InitDistance";%初期のegoとactの距離
    egoInitSpeed = "EgoInitSpeed";%egoの初期速度
    egoTargetSpeed = "EgoTargetSpeed";%egoの変更後速度
    egoAcc = "EgoAcceleration";%egoの加速度
    actInitSpeed = "ActorInitSpeed";%actorの初期速度
    actReactionTime = "ActorReactionTime";%actorの速度変更までの時間
    actTargetSpeed = "ActorTargetSpeed";%acotrの変更後速度
    actAcc = "ActorAcceleration";%actorの加速度
    pause(10);

    for j = 1:height(inputTable)

        maxSimulationTimes = inputTable.times(j);%シミュレーション回数
        value_dis = inputTable.InitDistance(j);%初期のegoとactの距離
        value_egoInitSpeed = inputTable.EgoInitSpeed(j);%egoの初期速度
        value_egoTargetSpeed = inputTable.EgoTargetSpeed(j);%egoの変更後速度
        value_egoAcc = inputTable.EgoAcceleration(j);%egoの加速度
        value_actInitSpeed = inputTable.ActorInitSpeed(j);%actorの初期速度
        value_actReactionTime = inputTable.ActorReactionTime(j);%actorの速度変更までの時間
        value_actTargetSpeed = inputTable.ActorTargetSpeed(j);%acotrの変更後速度
        value_actAcc = inputTable.ActorAcceleration(j);%actorの加速度   
        %上記の8つの値をシミュレーションに設定する
        setScenarioVariable(rrApp,dis,value_dis);
        setScenarioVariable(rrApp,egoInitSpeed,value_egoInitSpeed / 3.6);
        setScenarioVariable(rrApp,egoTargetSpeed,value_egoTargetSpeed / 3.6);
        setScenarioVariable(rrApp,egoAcc,value_egoAcc);
        setScenarioVariable(rrApp,actInitSpeed,value_actInitSpeed / 3.6);
        setScenarioVariable(rrApp,actReactionTime,value_actReactionTime);
        setScenarioVariable(rrApp,actTargetSpeed,value_actTargetSpeed / 3.6);
        setScenarioVariable(rrApp,actAcc,value_actAcc);
        SimDatas = controlSimDatas(value_egoInitSpeed,value_actInitSpeed, 1);

        for SimTimes = 1:maxSimulationTimes
            %シミュレーション開始
            set(rrSim,"SimulationCommand","Start");
            
            SimDatas.isEgoCompleted = false;
            SimDatas.isActCompleted = false;
            %リアルタイムでegoとactorの情報を得るための変数
            ego = []; 
            act = []; 
            
            %egoとactorが取得するできるまで待機
            while isempty(ego) || isempty(act)
                try    dcaseID = 'no58NkJvu366jusJSMypnstDt1_EOYr0J6Hrf8PSgsI_';
    partsID = 'Parts_fcx90cjb';
    userList = {'uaw_rebPBN_g9oDNrRmD0vs71jRfWeZ2HqZ_lu8idLE_'};
                    ego = Simulink.ScenarioSimulation.find("ActorSimulation", ActorID=uint64(1));
                    act = Simulink.ScenarioSimulation.find("ActorSimulation", ActorID=uint64(2));
                    pause(0.01);  
                catch
                    pause(0.01);
                end
            end       
            
            %シミュレーション実行中の処理
            while strcmp(get(rrSim,"SimulationStatus"),"Running")
                if ~isempty(ego) && ~isempty(act)%egoとacotorがシミュレーション中で削除されてないなら

                    %リアルタイムでデータを取得し、構造体にする
                    SimDatas.CreateRealtimeStructs( get(rrSim,"SimulationTime"), ...
                                                    getAttribute(ego,"Velocity"),getAttribute(act,"Velocity"),getAttribute(act,"AngularVelocity"), ...
                                                    getAttribute(ego,"Pose"),getAttribute(act,"Pose"), ...
                                                    '-');
                    %構造体にしたデータをjsonにする
                    sendData = SimDatas.jsonDataRealtime;
                    %jsonにしたデータを保存する
                    createJsonFile(realTimeDataJsonName,sendData)
                    %jsonデータをD-caseにアップロードする
                    dcase.uploadEvalData(sendData);
                end
                
                pause(1);%一秒待機
            end
            %以下はシミュレーション終了後の処理
            
            %ログデータの取得
            simLog = get(rrSim,"SimulationLog");

            %ログからego、actorの速度取得
            egoVelLog = get(simLog, 'Velocity','ActorID',1);
            actVelLog = get(simLog, 'Velocity','ActorID',2);

            %ログからego、actorの場所取得
            egoPosLog = get(simLog,"Pose","ActorID",1);
            actPosLog = get(simLog,"Pose","ActorID",2);

            %ログからegoの角速度取得
            egoAngVelLog = get(simLog, 'AngularVelocity','ActorID',1);



            %衝突判定の確認
            collisionMessages = false;%衝突判定simpleResultCsvName
            diagnostics = get(simLog, "Diagnostics");%エラーメッセージがあれば取得
    
            if ~isempty(diagnostics)%エラーメッセージがあるなら
                %メッセージ中にCollisionがあれば衝突がtrueになる
                collisionMessages = contains(string(diagnostics.Message), 'Collision');
            end
    
            if collisionMessages
                isCollision = 'Failed';%衝突あり(失敗
            else
                isCollision = 'Success';%衝突なし(成功
            end
            
            lastTime = length(egoVelLog);%シミュレーションの最終時間

            %最終時間でのデータを取得し、D-caseに送信
		    SimDatas.CreateRealtimeStructs( egoVelLog(lastTime).Time, ...
                                            egoVelLog(lastTime).Velocity,actVelLog(lastTime).Velocity, egoAngVelLog(lastTime).AngularVelocity,....
                                            egoPosLog(lastTime).Pose,actPosLog(lastTime).Pose, ...
                                            isCollision);
    
		    %構造体にしたデータをjsonにする
		    sendData = SimDatas.jsonDataRealtime;
		    %jsonにしたデータを保存する
		    createJsonFile('realtime.json',sendData)
            
		    %jsonデータをD-caseにアップロードする
		    dcase.uploadEvalData(sendData);
    
		    %Logからシミュレーション結果をまとめたデータを作成
		    SimDatas.CreateLogStructs( egoVelLog,actVelLog, ...
                                            egoPosLog,actPosLog, ...
                                            isCollision,value_dis, egoAngVelLog,...
                                            sprintf('n%s', string(SimTimes)));

		    %保存するためのjsonデータを作る
            logDataJson = jsonencode(SimDatas.dataLog);%Logデータをjson形式にする
            logDataJson = formatJSON(logDataJson);%jsonデータを見やすく清書する

            simpleResultJson = jsonencode(SimDatas.simpleResults);
            
            SimDatas.createSimpleResultStruct(value_actReactionTime,value_egoAcc,value_actInitSpeed,value_actAcc)
    
	        %結果を保存するjsonファイルを作成
            if SimTimes == 1 && j == 1%最初のシミュレーションなら
                % 新しくjsonファイルを作る
                createJsonFile(logDataJsonName,logDataJson);
                createJsonFile(simpleResultsJsonName,simpleResultJson);
    
            else%2回目以降のシミュレーションなら
                % 1回目で作ったjsonファイルに追記する
                appendJsonText(logDataJsonName,logDataJson);
                appendJsonText(simpleResultsJsonName,simpleResultJson);
    
            end
            
            %結果を保存するcsvファイルを作成
            T = struct2table(SimDatas.simpleResults);
            if isfile(simpleResultCsvName)
                writetable(T, simpleResultCsvName, 'WriteMode', 'append');
            else
                writetable(T, simpleResultCsvName);
            end
    
        end

    end
    
    %actReaという項目でソート
    sortedT = sortrows(readtable(simpleResultCsvName), 'actRea');
    writetable(sortedT, simpleResultCsvName);

catch ME%エラーが起きたら
    disp(getReport(ME, 'extended'));%エラーを表示
    %
end
close(rrApp);%シミュレーションを閉じる



function formatedJson = formatJSON(jsonData)
    jsonText = strrep(jsonData, '{"time"',sprintf('\n\t\t{"time"'));
    
   % 文字列の最初と最後を見つける
    firstBracePos = find(jsonText == '{', 1, 'first');
    lastBracePos = find(jsonText == '}', 1, 'last');
    
    % 文字列を3つの部分に分割して改行を追加
    beforeFirst = jsonText(1:firstBracePos);
    middle = jsonText(firstBracePos+1:lastBracePos-1);
    afterLast = jsonText(lastBracePos:end);
    
    % 改行を追加して結合
    formatedJson = [beforeFirst sprintf('\n\t') middle newline afterLast];
end

function createJsonFile(filename,  jsonData)
    try
        % ファイルが存在するかチェック
        if exist(filename, 'file')
   %         disp("ファイルを上書きします")
        end
        
        % 新規ファイルの作成
        fid = fopen(filename, 'w');
        if fid == -1
            error('ファイルを作成できませんでした: %s', filename);
        end
        
        % 初期JSONの構造を作成
        try
            % JSON形式で書き込み
            fprintf(fid, '%s', jsonData);
%            fprintf('新しいJSONファイルを作成しました: %s\n', filename);
            
        catch ME
            error('JSON形式が正しくありません: %s', ME.message);
        end
        
        % ファイルを閉じる
        fclose(fid);
        
    catch ME
        % エラーハンドリング
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        fprintf('エラーが発生しました: %s\n', ME.message);
        rethrow(ME);
    end
end
  
function appendJsonText(filename, jsonData)
    try
        % 既存のJSONファイルを読み込む
        fid = fopen(filename, 'r');
        if fid == -1
            error('ファイルを開けませんでした: %s', filename);
        end
        
        content = fscanf(fid, '%c', inf);
        fclose(fid);
        
        content = content(1:end-1);
        if length(content) > 2  % '{\n' より長い場合
            content = [content, ','];
        end
          
        % 新しいデータを整形
        newData = formatJSON(jsonData);
        % 最初の { と最後の } を除去
        newData = newData(2:end-1);
        
        % ファイルを書き込みモードで開く
        fid = fopen(filename, 'w');
        if fid == -1
            error('ファイルを開けませんでした: %s', filename);
        end
        
        % 結合したデータを書き込み
        fprintf(fid, '%s%s}', content, newData);
%        fprintf('JSONファイルに追記しました: %s\n', filename);
        
        % ファイルを閉じる
        fclose(fid);
            
    catch ME
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        rethrow(ME);
    end
end
