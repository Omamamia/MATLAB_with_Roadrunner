classdef hVehicle < matlab.System

    % Copyright 2022 The MathWorks, Inc.
    % properties (Access = private)
    properties (Access = public)
        mActorSimulationHdl; 
        mScenarioSimulationHdl; 
        mActor; 
        mLastTime = 0;
        CurrentVelocity;
        VelocityHistory = struct('time', {}, 'velocity', {}); % 新しいプロパティ
    end

    methods (Access=protected)
        function sz = getOutputSizeImpl(~)
            sz = [1 1];
        end

        function st = getSampleTimeImpl(obj)
            st = createSampleTime( ...
                obj, 'Type', 'Discrete', 'SampleTime', 0.02);
        end

        function t = getOutputDataTypeImpl(~)
            t = "double";
        end

        function resetImpl(obj)
            obj.VelocityHistory = struct('time', {}, 'velocity', {}); % 履歴をリセット
        end

        function setupImpl(obj)
            obj.mScenarioSimulationHdl = ...
                Simulink.ScenarioSimulation.find( ...
                    'ScenarioSimulation', 'SystemObject', obj);
            
            obj.mActorSimulationHdl = Simulink.ScenarioSimulation.find( ...
                'ActorSimulation', 'SystemObject', obj);

            obj.mActor.pose = ...
                obj.mActorSimulationHdl.getAttribute('Pose');

            obj.mActor.velocity = ...
                obj.mActorSimulationHdl.getAttribute('Velocity');
        end
        
        function stepImpl(obj, ~)
            currentTime = obj.getCurrentTime;
            elapsedTime = currentTime - obj.mLastTime;
            obj.mLastTime = currentTime;

            velocity = obj.mActor.velocity;
            % disp(velocity);
            
            % CurrentVelocityプロパティを更新
            obj.CurrentVelocity = velocity;
            % disp(obj.CurrentVelocity);
            
            % velocityの履歴を記録
            obj.VelocityHistory(end+1).time = currentTime;
            obj.VelocityHistory(end).velocity = velocity;

            pose = obj.mActor.pose;

            pose(1,4) = pose(1,4) + velocity(1) * elapsedTime; % x
            pose(2,4) = pose(2,4) + velocity(2) * elapsedTime; % y
            pose(3,4) = pose(3,4) + velocity(3) * elapsedTime; % z

            obj.mActor.pose = pose;
            
            obj.mActorSimulationHdl.setAttribute('Pose', pose);

            jsonStr = jsonencode(obj.VelocityHistory);
            fid = fopen('velocity_history.json', 'w');
            if fid == -1
                error('JSONファイルを作成できませんでした。');
            end
            fprintf(fid, '%s', jsonStr);
            fclose(fid);
            % disp('Velocity history saved to velocity_history.json');
        end

        function releaseImpl(obj)
            % シミュレーション終了時にJSONファイルを保存
            obj.saveVelocityHistoryToJson();
        end
    end

    % publicメソッドを追加してvelocityにアクセス
    methods (Access = public)
        function velocity = getVelocity(obj)
            velocity = obj.CurrentVelocity;
        end

        function saveVelocityHistoryToJson(obj)
            % VelocityHistoryをJSONファイルとして保存
            jsonStr = jsonencode(obj.VelocityHistory);
            fid = fopen('velocity_history.json', 'w');
            if fid == -1
                error('JSONファイルを作成できませんでした。');
            end
            fprintf(fid, '%s', jsonStr);
            fclose(fid);
            disp('Velocity history saved to velocity_history.json');
        end
    end
    
end