% APIエンドポイントURL
baseURL = 'https://www.matsulab.org/dcase/';
loginUrl = [baseURL 'api/login.php'];
uploadUrl = [baseURL 'api/uploadEvalData.php'];

% ユーザー認証情報
email = 'tier4.jp'; % ここに実際のメールアドレスを入力
password = 'tier4'; % ここに実際のパスワードを入力

% その他の必要な情報
dcaseID = 'jxlSYMp53SIn2BSJHo_5mnXt6Fb0iKKL_KRqfBJ3qao_';
partsID = 'Parts_0hft20qr';
userList = {'uaw_rebPBN_g9oDNrRmD0vs71jRfWeZ2HqZ_lu8idLE_'};

try
    % 認証リクエストの送信
    postData = sprintf('mail=%s&passwd=%s', urlencode(email), urlencode(password));
    options = weboptions('RequestMethod', 'post', 'ContentType', 'text');
    %response変数にサーバーからのレスポンスが格納される。
    response = webwrite(loginUrl, postData, options);
    
    % レスポンスからauthIDを抽出
    authData = jsondecode(response);
    if isfield(authData, 'authID')
        authID = authData.authID;
        fprintf('認証成功。authID: %s\n', authID);
    else
        error('認証レスポンスにauthIDが含まれていません。');
    end
    
    % 評価データの準備
    paramList = [struct('n', 1, 'value_bt', 1.94, 'value_bd', 4, 'value_st', 13.1, 'status', '-'), ...
                 struct('n', 1, 'value_bt', 1.94, 'value_bd', 4, 'value_st', 13.1, 'status', '-')];
    
    % デバッグ: paramListの内容を表示
    fprintf('送信するparamList:\n%s\n', jsonencode(paramList));
    
    % 評価データのアップロード
    uploadData = sprintf('authID=%s&dcaseID=%s&partsID=%s&userList=%s&paramList=%s', ...
                         urlencode(authID), ...
                         urlencode(dcaseID), ...
                         urlencode(partsID), ...
                         urlencode(jsonencode(userList)), ...
                         urlencode(jsonencode(paramList)));
    
    % デバッグ: 送信するデータを表示
    fprintf('送信するデータ:\n%s\n', uploadData);
    
    options = weboptions('RequestMethod', 'post', 'ContentType', 'text');
    response = webwrite(uploadUrl, uploadData, options);
    
    % レスポンスの表示
    fprintf('アップロード結果: %s\n', response);
    
catch ME
    fprintf('エラーが発生しました: %s\n', ME.message);
    fprintf('エラー識別子: %s\n', ME.identifier);
    disp(getReport(ME, 'extended'));
end