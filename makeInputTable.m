% CSVファイルを読み込む

%Names = string(T.Properties.VariableNames);

inputTable = struct('times', [], 'InitDistance', [], 'EgoInitSpeed', [], 'EgoTargetSpeed', [], 'EgoAcceleration', [] ...
                    ,'ActorInitSpeed', [],'ActorReactionTime', [],'ActorTargetSpeed', [],'ActorAcceleration', []);

range_dis = 82:104;
range_actInitSpeed = 30:48;
range_actAcc = [0.5,1.5,2.5];
range_actReactionTime = [1,1.5,2];

default_times = 1;

default_egoInitSpeed = 0;
default_egoTargetSpeed = 10;
default_egoAcceleration = 2.9;

default_actReactionTime = 100;
default_actorTargetSpeed = 40;
default_actAcc = 0;


for sp = range_actInitSpeed
    for dis = range_dis
        
        if sp > 40
            for acc = range_actAcc
                for rea = range_actReactionTime
                        inputTable.times(end+1) = default_times;
                        inputTable.InitDistance(end+1) = dis;
                        inputTable.EgoInitSpeed(end+1) = default_egoInitSpeed;
                        inputTable.EgoTargetSpeed(end+1) = default_egoTargetSpeed;
                        inputTable.EgoAcceleration(end+1) = default_egoAcceleration;
                        inputTable.ActorInitSpeed(end+1) = sp;
                        inputTable.ActorTargetSpeed(end+1) = default_actorTargetSpeed;

                        inputTable.ActorReactionTime(end+1) = rea;
                        inputTable.ActorAcceleration(end+1) = acc;
                        
                end
            end
        else
            inputTable.times(end+1) = default_times;
            inputTable.InitDistance(end+1) = dis;
            inputTable.EgoInitSpeed(end+1) = default_egoInitSpeed;
            inputTable.EgoTargetSpeed(end+1) = default_egoTargetSpeed;
            inputTable.EgoAcceleration(end+1) = default_egoAcceleration;
            inputTable.ActorInitSpeed(end+1) = sp;
            inputTable.ActorTargetSpeed(end+1) = sp;

            inputTable.ActorReactionTime(end+1) = default_actReactionTime;
            inputTable.ActorAcceleration(end+1) = default_actAcc;   
        end
    end
end

% 構造体を縦長に展開
numEntries = numel(inputTable.times); % 構造体のエントリ数
expandedTable = table();

% 各フィールドをテーブル形式に変換して結合
expandedTable.times = inputTable.times(:);
expandedTable.InitDistance = inputTable.InitDistance(:);
expandedTable.EgoInitSpeed = inputTable.EgoInitSpeed(:);
expandedTable.EgoTargetSpeed = inputTable.EgoTargetSpeed(:);
expandedTable.EgoAcceleration = inputTable.EgoAcceleration(:);
expandedTable.ActorInitSpeed = inputTable.ActorInitSpeed(:);
expandedTable.ActorReactionTime = inputTable.ActorReactionTime(:);
expandedTable.ActorTargetSpeed = inputTable.ActorTargetSpeed(:);
expandedTable.ActorAcceleration = inputTable.ActorAcceleration(:);

% CSVファイルとして保存
csvFileName = 'inputTable_vertical.csv'; % 保存するファイル名
writetable(expandedTable, csvFileName);

% 保存完了メッセージ
disp(['縦長のCSVファイルとして保存しました: ' csvFileName]);

