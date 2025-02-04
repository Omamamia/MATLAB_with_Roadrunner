classdef dcaseCommunication < handle
    properties
        % -----------------------------------------------------------
        % 各種URLの設定（D-Case Communicatorとの通信に使用）
        % -----------------------------------------------------------
        % baseURL = 'https://www.matsulab.org/dcase/'; % D-Case CommunicatorのベースURL（現在は未使用）
        loginUrl = 'https://www.matsulab.org/dcase/api/login.php'; % ログイン用のAPIエンドポイント
        uploadUrl = 'https://www.matsulab.org/dcase/api/uploadEvalData.php'; % データアップロード用のAPIエンドポイント

        % -----------------------------------------------------------
        % ユーザー認証に必要な情報
        % -----------------------------------------------------------
        email         % ログイン用のメールアドレス
        password      % ログイン用のパスワード
        authID;       % 認証に成功した際にサーバから返される認証ID

        % -----------------------------------------------------------
        % D-Caseに関するその他のパラメータ
        % -----------------------------------------------------------
        dcaseID   % D-Caseを識別するためのID
        partsID   % D-Case内の各ノードを識別するためのID
        userList  % D-Caseに参加しているユーザーのリスト

        % -----------------------------------------------------------
        % 送信するJSONファイルのパス（必要に応じて利用）
        % -----------------------------------------------------------
        jsonFilePath % D-Caseに送信するJSONファイルのパス
    end

    methods
        % ===========================================================
        % コンストラクタ
        % オブジェクト生成時に必要なパラメータを設定し、認証処理を実行する
        % ===========================================================
        function obj = dcaseCommunication(email, password, dcaseID, partsID, userList)
            % 各プロパティに引数から受け取った値を代入
            obj.email = email;            % ログイン用メールアドレスの設定
            obj.password = password;      % ログイン用パスワードの設定
            obj.dcaseID = dcaseID;        % D-Case識別用IDの設定
            obj.partsID = partsID;        % ノード識別用IDの設定
            obj.userList = userList;      % ユーザーリストの設定

            % サーバに対して認証処理を実行し、authIDを取得する
            authenticateUser(obj);
        end

        % ===========================================================
        % 認証処理を行う関数
        % サーバにログイン情報をPOSTし、認証ID（authID）を取得する
        % ===========================================================
        function authID = authenticateUser(obj)
            % -----------------------------------------------------------
            % ログイン用データの作成
            % urlencode関数を使用して、メールアドレスとパスワードの
            % 特殊文字をエンコードする（URL内で安全に使用できるようにする）
            % -----------------------------------------------------------
            postData = sprintf('mail=%s&passwd=%s', urlencode(obj.email), urlencode(obj.password));
            
            % -----------------------------------------------------------
            % webwrite用オプションの設定
            % RequestMethodを'post'、ContentTypeを'text'に指定
            % -----------------------------------------------------------
            options = weboptions('RequestMethod', 'post', 'ContentType', 'text');
            
            % -----------------------------------------------------------
            % ログイン用URLへPOSTリクエストを送信し、サーバからのレスポンスを取得
            % -----------------------------------------------------------
            response = webwrite(obj.loginUrl, postData, options);
            
            % -----------------------------------------------------------
            % サーバからのレスポンス（JSON形式）をデコードし、構造体に変換
            % -----------------------------------------------------------
            authData = jsondecode(response);
            
            % -----------------------------------------------------------
            % レスポンスに認証ID（authID）が含まれているかをチェック
            % -----------------------------------------------------------
            if isfield(authData, 'authID')
                % 認証IDが存在する場合、認証に成功とみなしauthIDを取得
                authID = authData.authID;  % サーバから取得した認証IDをローカル変数に保存
                obj.authID = authID;       % オブジェクトのプロパティに認証IDを格納
                % fprintf('認証成功。authID: %s\n', authID); % （デバッグ用のメッセージ、必要に応じて表示）
            else
                % 認証に失敗した場合、エラーメッセージを出力して処理を中断
                error('認証に失敗しました。');
            end
        end

        % ===========================================================
        % データアップロード処理を行う関数
        % 更新されたパラメータをD-Caseに送信する（簡略化版）
        % ===========================================================
        function response = uploadEvalData(obj, paramList)
            % -----------------------------------------------------------
            % paramListのフォーマット整形
            % 文字列paramListをJSON配列の一部として整形する
            % -----------------------------------------------------------
            formatedParamList = sprintf('[{},%s]', paramList);

            % -----------------------------------------------------------
            % アップロード用データの作成
            % 各パラメータをURLエンコードしてPOSTデータとして連結する
            % userListはjsonencodeでJSON形式の文字列に変換する
            % -----------------------------------------------------------
            uploadData = sprintf('authID=%s&dcaseID=%s&partsID=%s&userList=%s&paramList=%s', ...
                urlencode(obj.authID), ...         % 認証IDのエンコード
                urlencode(obj.dcaseID), ...          % D-Case IDのエンコード
                urlencode(obj.partsID), ...          % ノードIDのエンコード
                jsonencode(obj.userList), ...        % ユーザーリストをJSON文字列に変換
                formatedParamList);                  % 整形済みのパラメータリスト

            % -----------------------------------------------------------
            % webwrite用オプションの設定
            % -----------------------------------------------------------
            options = weboptions('RequestMethod', 'post', 'ContentType', 'text');
            
            % -----------------------------------------------------------
            % アップロード用URLへPOSTリクエストを送信し、レスポンスを取得する
            % -----------------------------------------------------------
            response = webwrite(obj.uploadUrl, uploadData, options);
        end

    end

end