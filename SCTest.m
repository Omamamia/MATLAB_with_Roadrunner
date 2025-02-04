try  
    % -----------------------------------------------------------
    % ログインおよびD-Caseとの通信に必要な情報の設定
    % -----------------------------------------------------------
    email = 'tier4.jp'; % ログイン用メールアドレス（D-CaseサーバにアクセスするためのユーザーID）
    password = 'tier4'; % ログイン用パスワード
    
    % D-Case通信に必要なその他の情報を設定
    dcaseID = 'ZOkeBMC80fOHeAkjkswqBu8hveyXxdtQSJxhDEr4qUw_'; % D-Caseを識別するID
    partsID = 'Parts_qypn1wir';  % D-Case内のノードや部品を識別するID
    userList = {'uaw_rebPBN_g9oDNrRmD0vs71jRfWeZ2HqZ_lu8idLE_'}; % D-Caseに参加しているユーザーのリスト

    % dcaseCommunicationクラスのコンストラクタを呼び出し、
    % 上記の認証情報や識別子を使ってD-Caseサーバとの通信を確立する
    dcase = dcaseCommunication(email, password, dcaseID, partsID, userList);

    % -----------------------------------------------------------
    % ファイル名の定義（入力パラメータ、各種結果の保存先）
    % -----------------------------------------------------------
    inputTableName = 'inputTest.csv';         % 入力パラメータが記載されたCSVファイル名
    realTimeDataJsonName = 'realtimeTest.json'; % シミュレーション中のリアルタイムデータを保存するJSONファイル名
    logDataJsonName = 'resultTest.json';        % シミュレーション全体のログデータを保存するJSONファイル名
    resultsJsonName = 'resultSimpletest.json';  % 最終結果をまとめたJSONファイル名
    resultCsvName = 'outputTest.csv';           % 最終結果をCSV形式で保存するためのファイル名

    % -----------------------------------------------------------
    % RoadRunner（シナリオシミュレーション環境）の起動と設定
    % -----------------------------------------------------------
    % 作業プロジェクトのパスを指定（RoadRunner用のプロジェクトフォルダ）
    rrproj = "/home/furuuchi/ドキュメント/GitHub/Roadrunner";
    % RoadRunnerアプリケーションを起動。InstallationFolderパラメータで実行ファイルの場所を指定
    rrApp = roadrunner(rrproj, InstallationFolder="/usr/local/RoadRunner_R2024b/bin/glnxa64");
    
    % シナリオファイル（RoadRunnerで実行するシナリオ）のパスを指定
    scenarioFile = "/home/furuuchi/ドキュメント/GitHub/Roadrunner/Scenarios/Testcase_pre2-rightupdate.rrscenario";
    % 指定したシナリオファイルをRoadRunner上で読み込み、開く
    openScenario(rrApp, scenarioFile);
    
    % RoadRunner上でシミュレーションを実行するためのシミュレーションオブジェクトを作成
    rrSim = createSimulation(rrApp);

    % -----------------------------------------------------------
    % シミュレーション実行前の基本設定
    % -----------------------------------------------------------
    % シミュレーションのログ取得を有効にする（後の解析用にシミュレーションデータを記録）
    set(rrSim, "Logging", "on");
    % シミュレーションのPacer（実行速度制御）をオンにし、倍速などの実行を許可する
    set(rrSim, PacerStatus="On");
    
    % シミュレーションの時間設定
    maxSimulationTimeSec = 15; % シミュレーションの最大実行時間（秒）
    StepSize = 0.02;           % シミュレーションの更新間隔（秒）：何秒ごとに状態更新・データ取得を行うか
    simulationPace = 20;       % シミュレーション実行の速度倍率（例：20倍速で実行）
    
    % 上記のシミュレーションパラメータを、シミュレーションオブジェクトに適用する
    set(rrSim, 'MaxSimulationTime', maxSimulationTimeSec);
    set(rrSim, 'StepSize', StepSize);
    set(rrSim, SimulationPace = simulationPace);    
    
    % -----------------------------------------------------------
    % シナリオ変数の名称定義
    % -----------------------------------------------------------
    % 以下の文字列は、RoadRunnerシナリオ内で定義された変数名と一致させる必要がある
    dis = "InitDistance";        % 初期状態でのEgoとActor間の距離
    egoInitSpeed = "EgoInitSpeed"; % Egoの初期速度
    egoTargetSpeed = "EgoTargetSpeed"; % Egoの変速後目標速度
    egoAcc = "EgoAcceleration";    % Egoの加速度
    actInitSpeed = "ActorInitSpeed";   % Actorの初期速度
    actReactionTime = "ActorReactionTime"; % Actorが速度変更を開始するまでの反応時間
    actTargetSpeed = "ActorTargetSpeed";   % Actorの変速後目標速度
    actAcc = "ActorAcceleration";  % Actorの加速度

    % -----------------------------------------------------------
    % シミュレーションデータ管理クラスのインスタンス生成
    % -----------------------------------------------------------
    % controlSimDatas_Refacクラスは、シミュレーション実行中のデータ取得、ログ作成、
    % 最終結果の算出などを担う
    simDatas = controlSimDatas(rrSim);

    % 入力パラメータファイルを読み込み、simDatasオブジェクトに設定する
    simDatas.readTable(inputTableName);

    % -----------------------------------------------------------
    % 各入力条件ごとにシミュレーションを実施するループ
    % -----------------------------------------------------------
    for j = 1:height(simDatas.inputTable)
        % 現在の行（条件）に対応するパラメータを設定
        simDatas.setInput(j);
        
        % 各パラメータ値をシナリオ変数に反映する
        % ※速度はkm/hからm/sに換算するため、3.6で割る
        setScenarioVariable(rrApp, dis, simDatas.value_dis);
        setScenarioVariable(rrApp, egoInitSpeed, simDatas.value_egoInitSpeed / 3.6);
        setScenarioVariable(rrApp, egoTargetSpeed, simDatas.value_egoTargetSpeed / 3.6);
        setScenarioVariable(rrApp, egoAcc, simDatas.value_egoAcc);
        setScenarioVariable(rrApp, actInitSpeed, simDatas.value_actInitSpeed / 3.6);
        setScenarioVariable(rrApp, actReactionTime, simDatas.value_actReactionTime);
        setScenarioVariable(rrApp, actTargetSpeed, simDatas.value_actTargetSpeed / 3.6);
        setScenarioVariable(rrApp, actAcc, simDatas.value_actAcc);

        % 指定されたシミュレーション回数分（同一条件下の複数試行）ループする
        for n = 1:simDatas.maxSimulationTimes
            
            % シミュレーション実行前の状態を初期化する
            simDatas.Init();
            % 総シミュレーション回数をインクリメント（各試行の識別用）
            simDatas.simTimes = simDatas.simTimes + 1;
            
            % シミュレーションの開始コマンドを送信
            set(rrSim, "SimulationCommand", "Start");
            
            % シナリオ内のEgoおよびActorオブジェクトが取得できるまで待機する
            simDatas.setEgoAndActor();
            
            % -----------------------------------------------------------
            % シミュレーション実行中の処理（リアルタイムデータの取得と送信）
            % -----------------------------------------------------------
            while strcmp(get(rrSim, "SimulationStatus"), "Running")
                try
                    % シミュレーション内の各種センサデータ（速度、加速度、角速度、距離など）を取得し、
                    % realtimeData構造体にまとめる
                    simDatas.createRealtimeStructs();
                    
                    % 取得したリアルタイムデータ構造体をJSON形式の文字列に変換する
                    sendData = jsonencode(simDatas.realtimeData);
                    
                    % JSON形式の文字列を指定ファイルに保存する（上書き保存）
                    createJsonFile(realTimeDataJsonName, sendData)
                    
                    % 生成したJSONデータをD-Caseサーバにアップロードする
                    dcase.uploadEvalData(sendData);
                    
                    % コンソールにJSONデータを表示（デバッグ用）
                    disp(sendData)
                end
                
                % 次の更新まで、シミュレーションのステップサイズ分（例：0.02秒）待機する
                pause(StepSize);
            end
            % -----------------------------------------------------------
            % シミュレーション終了後の処理（ログデータの作成・結果の送信）
            % -----------------------------------------------------------
            % シミュレーション実行中に収集したデータから、詳細なログ構造体を作成する
            simDatas.createLogStructs();

            % 最終時刻のシミュレーション結果（dataLog.Resultsの最終要素）を取得し、
            % JSON形式に変換してD-Caseにアップロードする
            sendData = simDatas.dataLog.Results(simDatas.logLength);
            sendData = jsonencode(sendData);
            
            % JSON形式データをファイルに保存する（上書き）
            createJsonFile(realTimeDataJsonName, sendData)
            % JSONデータをD-Caseサーバにアップロード
            dcase.uploadEvalData(sendData);
    
            % -----------------------------------------------------------
            % ログ全体のJSONデータを生成し、保存・追記する処理
            % -----------------------------------------------------------
            % シミュレーション中に収集した全ログデータ（dataLog構造体）をJSONに変換
            logDataJson = jsonencode(simDatas.dataLog);
            % JSON文字列を整形して、見やすい形式（改行・インデント付き）にする
            logDataJson = formatJSON(logDataJson);

            % 指定したファイルが存在しなければ、新規作成、存在すれば追記する
            if ~isfile(logDataJsonName)
                createJsonFile(logDataJsonName, logDataJson);
            else
                appendJsonText(logDataJsonName, logDataJson);
            end

            % -----------------------------------------------------------
            % 最終結果の算出と保存（JSONおよびCSV形式）
            % -----------------------------------------------------------
            % 各試行の結果（評価指標）を計算し、resultsStructにまとめる
            simDatas.createResultStruct();
            % 結果構造体をJSON形式に変換
            resultsJson = jsonencode(simDatas.resultsStruct);            
	        % 結果JSONファイルが存在しなければ新規作成、存在すれば追記する
            if ~isfile(resultsJsonName)
                createJsonFile(resultsJsonName, resultsJson);
            else
                appendJsonText(resultsJsonName, resultsJson);
            end

            % 結果構造体をテーブルに変換し、CSVファイルとして保存する
            resultTable = struct2table(simDatas.resultsStruct);
            if ~isfile(resultCsvName)
                writetable(resultTable, resultCsvName);                
            else
                writetable(resultTable, resultCsvName, 'WriteMode', 'append');
            end
    
        end

    end
    
    % -----------------------------------------------------------
    % すべてのシミュレーション試行終了後の最終処理
    % -----------------------------------------------------------
    % CSVファイルに記録された結果を、'actRea'（Actorの反応時間）でソートして再保存する
    sortedresultTable = sortrows(readtable(resultCsvName), 'actRea');
    writetable(sortedresultTable, resultCsvName);
    

catch ME  % 例外が発生した場合の処理
    % 詳細なエラーレポート（スタックトレースなど）をコンソールに表示する
    disp(getReport(ME, 'extended'));
end

% RoadRunnerアプリケーションを終了して、リソースを解放する
close(rrApp);


% -----------------------------------------------------------
% 以下、JSONデータの整形・ファイル操作用の補助関数群
% -----------------------------------------------------------

function formatedJson = formatJSON(jsonData)
    % -----------------------------------------------------------
    % この関数は、JSON形式の文字列に改行とタブを追加し、
    % 人間が読みやすいフォーマットに整形するための関数です。
    %
    % 入力:
    %   jsonData - 元のJSON形式の文字列
    % 出力:
    %   formatedJson - 整形済みのJSON文字列
    % -----------------------------------------------------------
    
    % 文字列中の '{"time"' を改行とタブを追加した形に置換
    jsonText = strrep(jsonData, '{"time"', sprintf('\n\t\t{"time"'));
    
    % JSON文字列の最初の '{' と最後の '}' の位置を特定する
    firstBracePos = find(jsonText == '{', 1, 'first');
    lastBracePos = find(jsonText == '}', 1, 'last');
    
    % 文字列を、最初の部分、中間部分、最後の部分に分割し、
    % それぞれに改行やタブを挿入して読みやすくする
    beforeFirst = jsonText(1:firstBracePos);
    middle = jsonText(firstBracePos+1:lastBracePos-1);
    afterLast = jsonText(lastBracePos:end);
    
    % 分割した部分を結合して、整形済みのJSON文字列を生成
    formatedJson = [beforeFirst sprintf('\n\t') middle newline afterLast];
end

function createJsonFile(filename, jsonData)
    % -----------------------------------------------------------
    % この関数は、指定されたファイル名で新規にJSONファイルを作成し、
    % 引数jsonDataの内容をJSON形式でファイルに書き込むための関数です。
    %
    % 入力:
    %   filename - 作成するファイル名
    %   jsonData - 書き込むJSON形式の文字列
    % -----------------------------------------------------------
    try
        % 指定されたファイルが既に存在するかチェック（存在しても上書きする）
        if exist(filename, 'file')
            % (必要に応じて上書きの旨を表示可能)
        end
        
        % ファイルを 'w' モード（書き込みモード）でオープンする
        fid = fopen(filename, 'w');
        if fid == -1
            error('ファイルを作成できませんでした: %s', filename);
        end
        
        % JSON形式の文字列をファイルに書き込む
        try
            fprintf(fid, '%s', jsonData);
        catch ME
            error('JSON形式が正しくありません: %s', ME.message);
        end
        
        % 書き込み完了後、ファイルを閉じる
        fclose(fid);
        
    catch ME
        % エラー発生時は、ファイルがオープン中なら閉じ、エラーメッセージを表示後に再送出
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        fprintf('エラーが発生しました: %s\n', ME.message);
        rethrow(ME);
    end
end
  
function appendJsonText(filename, jsonData)
    % -----------------------------------------------------------
    % この関数は、既存のJSONファイルに対して、新たなJSONデータを追記するための関数です。
    %
    % 入力:
    %   filename - 既存のJSONファイル名
    %   jsonData - 追記する新たなJSON形式の文字列
    % -----------------------------------------------------------
    try
        % 既存のJSONファイルを読み込み、全内容を文字列として取得する
        fid = fopen(filename, 'r');
        if fid == -1
            error('ファイルを開けませんでした: %s', filename);
        end
        content = fscanf(fid, '%c', inf);
        fclose(fid);
        
        % ファイル内容の末尾の文字（通常は閉じ括弧）を削除
        content = content(1:end-1);
        % ファイル内容が十分な長さの場合、末尾にカンマを追加して新データとの区切りとする
        if length(content) > 2  % 例：'{\n' より長い場合
            content = [content, ','];
        end
          
        % 新たに追記するJSONデータを整形する
        newData = formatJSON(jsonData);
        % 新データの最初の '{' と最後の '}' を除去する（既存のJSONオブジェクトに追記するため）
        newData = newData(2:end-1);
        
        % ファイルを再度 'w' モードでオープンし、更新した内容を書き込む
        fid = fopen(filename, 'w');
        if fid == -1
            error('ファイルを開けませんでした: %s', filename);
        end
        
        % 既存の内容と新しいデータを結合し、最後に閉じ括弧を追加して書き込む
        fprintf(fid, '%s%s}', content, newData);
        
        % ファイル書き込み完了後、ファイルを閉じる
        fclose(fid);
            
    catch ME
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        rethrow(ME);
    end
end