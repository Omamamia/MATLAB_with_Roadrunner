classdef controlSimDatas < handle
    properties
		dataRealtime = struct('time', [],'egoAngularVelocity', [], 'egoVelocity', [], 'egoSpeed', [] ,'egoSpeedHorizontal', [],'egoSpeedVertical', [],'egoAcc',[], 'actVelocity', [], 'actSpeed', [] ,'actAcc',[],'dis', [],'isCollision',[]);
        previousData = struct('time', [],'egoAngularVelocity', [], 'egoSpeed', [],'egoSpeedHorizontal', [],'egoSpeedVertical', [], 'actSpeed', []);
        simpleResults = struct('times',[], 'actRea',  [], 'egoAcc', [], 'actVel', [], 'actAcc', [], 'disInit', [],'DTC', [],'PET', [],'isCollision', []);
        jsonDataRealtime

                    isEgoCompletedTime = 999999;
            isActCompletedTime = 999999;

        disMin
             
        dataLog
        
        egoVelLog
        actVelLog
        
        egoPosLog
        actPosLog
        
        timeLog
        disLog
        
		isCollision
        isEgoCompleted
        isActCompleted

        r
        n
        
        PET

    end
    methods

        function obj = controlSimDatas(initEgoSpeed,initActSpeed,n)
           obj.previousData.time = 0;
            obj.previousData.egoSpeed = initEgoSpeed;
            obj.previousData.atSpeed = initActSpeed;
            obj.r =5.88;
            obj.n = n;
            obj.isEgoCompleted = false;
            obj.isActCompleted = false;
            obj.PET = 0;
        end

        function createSimpleResultStruct(obj,actRea,egoAcc,actVel,actAcc)
            obj.simpleResults.times = obj.n;
            obj.simpleResults.actRea = mod(actRea , 100);
            obj.simpleResults.egoAcc = egoAcc;
            obj.simpleResults.actVel = actVel;
            obj.simpleResults.actAcc = actAcc;
            obj.simpleResults.disInit = obj.dataLog.InitDis;
            obj.simpleResults.isCollision = obj.dataLog.isCollision;
            obj.simpleResults.DTC = obj.disMin;
            obj.simpleResults.PET = obj.PET;
            
            obj.n = obj.n + 1;

        end

        function CreateRealtimeStructs(obj,time,egoVel,actVel,egoAngVel,egoPos,actPos,isCollision)
                obj.dataRealtime.time  = time;

                obj.dataRealtime.egoVelocity = egoVel;
                obj.dataRealtime.actVelocity = actVel;

                obj.dataRealtime.egoSpeed = norm(obj.dataRealtime.egoVelocity);
                obj.dataRealtime.actSpeed = norm(obj.dataRealtime.actVelocity);

                obj.dataRealtime.egoAcc = (obj.dataRealtime.egoSpeed - obj.previousData.egoSpeed) / (obj.dataRealtime.time - obj.previousData.time);
                obj.dataRealtime.actAcc = (obj.dataRealtime.actSpeed - obj.previousData.actSpeed) / (obj.dataRealtime.time - obj.previousData.time);
                % 
                % if obj.dataRealtime.egoSpeed < 0.001 && obj.dataRealtime.egoAcc < 0
                %     obj.isEgoCompleted = true;
                % end
                % 
                % if obj.dataRealtime.actSpeed < 0.001 && obj.dataRealtime.actAcc < 0 && obj.isActCompleted == false
                %     obj.isActCompleted = true;
                %     obj.PET = time;
                % end
                % 
                 obj.dataRealtime.dis = norm(egoPos(1:3, 4) - actPos(1:3, 4)) - obj.r;
                % 
                % if obj.isEgoCompleted == true
                %     obj.dataRealtime.dis = 999;
                % end

                obj.dataRealtime.isCollision = isCollision;
                
                obj.previousData.time = obj.dataRealtime.time;
                obj.previousData.egoSpeed = obj.dataRealtime.egoSpeed;
                obj.previousData.actSpeed = obj.dataRealtime.actSpeed;
    
                obj.jsonDataRealtime = jsonencode(obj.dataRealtime);
                disp(obj.dataRealtime)
%                createJsonFile('realtime.json',obj.jsonDataRealtime)
        end
        
        function CreateLogStructs(obj,egoVel,actVel,egoPos,actPos,isCollision,InitDis,egoAngVelLog,fieldName)



            obj.dataLog = struct(   'isCollision', isCollision, ...
                             'InitDis', InitDis, ...
                             'SimulationTime', egoVel(length(egoVel)).Time ,...
                              fieldName, []);
          
        
            for i = 1:length(egoVel)
                obj.dataLog.(fieldName)(i).time = egoVel(i).Time*1000;

                obj.dataLog.(fieldName)(i).egoAngVelLog = rad2deg(egoAngVelLog(i).AngularVelocity(3));
        
                obj.dataLog.(fieldName)(i).egoVelocity =egoVel(i).Velocity;
                obj.dataLog.(fieldName)(i).egoSpeed = norm(egoVel(i).Velocity);
                obj.dataLog.(fieldName)(i).egoSpeedHorizontal = obj.dataLog.(fieldName)(i).egoSpeed * sind(obj.dataLog.(fieldName)(i).egoAngVelLog);
                obj.dataLog.(fieldName)(i).egoSpeedVertical = obj.dataLog.(fieldName)(i).egoSpeed * cosd(obj.dataLog.(fieldName)(i).egoAngVelLog);
        
                if i == 1
                    obj.dataLog.(fieldName)(i).egoAcc = 0; 
                    obj.dataLog.(fieldName)(i).egoAccVertical = 0; 

                    obj.dataLog.(fieldName)(i).egoAccHorizontal = 0; 
                else
                    obj.dataLog.(fieldName)(i).egoAcc = (obj.dataLog.(fieldName)(i).egoSpeed - obj.dataLog.(fieldName)(i - 1).egoSpeed) ...
                       / (obj.dataLog.(fieldName)(i).time - obj.dataLog.(fieldName)(i - 1).time) * 1000;
                    obj.dataLog.(fieldName)(i).egoAccVertical = (obj.dataLog.(fieldName)(i).egoSpeedVertical - obj.dataLog.(fieldName)(i - 1).egoSpeedVertical) ...
                       / (obj.dataLog.(fieldName)(i).time - obj.dataLog.(fieldName)(i - 1).time) * 1000;
                    obj.dataLog.(fieldName)(i).egoAccHorizontal = (obj.dataLog.(fieldName)(i).egoSpeedHorizontal - obj.dataLog.(fieldName)(i - 1).egoSpeedHorizontal) ...
                       / (obj.dataLog.(fieldName)(i).time - obj.dataLog.(fieldName)(i - 1).time) * 1000;
                end
        
                obj.dataLog.(fieldName)(i).actVelocity =actVel(i).Velocity;
                obj.dataLog.(fieldName)(i).actSpeed = norm(actVel(i).Velocity);
                if i == 1
                    obj.dataLog.(fieldName)(i).actAcc = 0; 
                else
                    obj.dataLog.(fieldName)(i).actAcc = (obj.dataLog.(fieldName)(i).actSpeed - obj.dataLog.(fieldName)(i - 1).actSpeed) ...
                       / (obj.dataLog.(fieldName)(i).time - obj.dataLog.(fieldName)(i - 1).time);
                end
                
                obj.dataLog.(fieldName)(i).dis = norm(egoPos(i).Pose(1:3, 4) - actPos(i).Pose(1:3, 4)) - obj.r;

                if obj.dataLog.(fieldName)(i).egoSpeed == 0 && obj.dataLog.(fieldName)(i).egoAcc < 0
                    obj.isEgoCompleted = true;
                    obj.isEgoCompletedTime = obj.dataLog.(fieldName)(i).time;
                end

                if obj.dataLog.(fieldName)(i).actSpeed < 0.001 && obj.dataLog.(fieldName)(i).actAcc < 0 && obj.isActCompleted == false
                    obj.isActCompleted = true;
                    obj.isActCompletedTime = obj.dataLog.(fieldName)(i).time;
                    obj.PET = obj.isActCompletedTime - obj.isEgoCompletedTime  ;
                end
                              
                
                if obj.isEgoCompleted == true
                    obj.dataLog.(fieldName)(i).dis = 999;
                end

            end
            obj.disMin =  min([obj.dataLog.(fieldName).dis]);
        
        end


    end
end