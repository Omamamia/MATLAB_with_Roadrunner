classdef dcaseCommunication < handle
    properties
        baseURL = 'https://www.matsulab.org/dcase/';
        loginUrl = 'https://www.matsulab.org/dcase/api/login.php';
        uploadUrl = 'https://www.matsulab.org/dcase/api/uploadEvalData.php';

        email% ここに実際のメールアドレスを入力
        password% ここに実際のパスワードを入力
        authID;
        
        % その他の必要な情報
        dcaseID
        partsID
        userList
        
        % JSONファイルのパスを指定
        jsonFilePath % ここに実際のJSONファイルのパスを入力
    end

    methods
        function obj = dcaseCommunication(email,password,dcaseID,partsID,userList)
                obj.email = email;
                obj.password = password;
                obj.dcaseID = dcaseID;
                obj.partsID = partsID;
                obj.userList = userList;
                authenticateUser(obj);
        end

        % 認証処理を行う関数
        function authID = authenticateUser(obj)
            
            postData = sprintf('mail=%s&passwd=%s', urlencode(obj.email), urlencode(obj.password));
            options = weboptions('RequestMethod', 'post', 'ContentType', 'text');
            response = webwrite(obj.loginUrl, postData, options);
            
            authData = jsondecode(response);
            if isfield(authData, 'authID')
                authID = authData.authID;
                obj.authID = authID;
%                fprintf('認証成功。authID: %s\n', authID);
            else
                error('認証に失敗しました。');
            end
        end
        % 更新されたパラメータをアップロードする関数（簡略化版）
        function response = uploadEvalData(obj,paramList)

            formatedParamList = sprintf('[{},%s]',paramList);

            uploadData = sprintf('authID=%s&dcaseID=%s&partsID=%s&userList=%s&paramList=%s', ...
                urlencode(obj.authID), ...
                urlencode(obj.dcaseID), ...
                urlencode(obj.partsID), ...
                jsonencode(obj.userList), ...
                formatedParamList);
      %      disp(uploadData)
            options = weboptions('RequestMethod', 'post', 'ContentType', 'text');
            response = webwrite(obj.uploadUrl, uploadData, options);
            
    %        fprintf('アップロード結果: %s\n', response);
        end

    end

end
