#include "sf.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QDateTime>

StudentFinance::StudentFinance(QObject *parent) : QObject(parent) {
    networkManager = new QNetworkAccessManager(this);

// I/O SAVED DATA
    QSettings settings("ZayanDev", "MyFinanceAI");
    apiKey = settings.value("apiKey", "").toString();
    balance = settings.value("savedBalance", 0.0).toDouble();
}

void StudentFinance::setApiKey(const QString &key) {
    apiKey = key.trimmed();

    QSettings settings("ZayanDev", "MyFinanceAI");
    settings.setValue("apiKey", apiKey);

}

QString StudentFinance::getApiKey() {
    return apiKey;
}

void StudentFinance::deleteTransaction(QString type, double amount) {
    if (type == "income") balance -= amount;
    else if (type == "expense") balance += amount;

    QSettings settings("ZayanDev", "MyFinanceAI");
    settings.setValue("savedBalance", balance);

    emit balanceChanged();
}

QString StudentFinance::getCurrentBalance() const {
    return QString("PKR %1").arg(balance, 0, 'f', 2);
}

void StudentFinance::processInput(const QString &userInput) {
    if(apiKey.isEmpty()) {
        emit apiError("Please set your API Key first via the settings button!");
        return;
    }

    QString urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=" + apiKey;
    QNetworkRequest request((QUrl(urlString)));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QString systemPrompt = "You are a financial parser. Respond ALWAYS with a JSON ARRAY of objects. Include 'type' (income/expense), 'amount' (number), 'category' (string), and 'description' (string).";

    QJsonObject payload;
    QJsonObject sysInst { {"parts", QJsonArray{ QJsonObject{{"text", systemPrompt}} } } };
    payload["system_instruction"] = sysInst;

    QJsonArray contents { QJsonObject{{"parts", QJsonArray{ QJsonObject{{"text", userInput}} } }} };
    payload["contents"] = contents;

    QJsonObject genConfig { {"response_mime_type", "application/json"}, {"temperature", 0.0} };
    payload["generationConfig"] = genConfig;

    QByteArray postData = QJsonDocument(payload).toJson();

    QNetworkReply *reply = networkManager->post(request, postData);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onApiReply(reply); });
}

void StudentFinance::onApiReply(QNetworkReply *reply) {
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
        QJsonObject rootObj = jsonDoc.object();

        QJsonArray candidates = rootObj["candidates"].toArray();
        QString contentStr = candidates[0].toObject()["content"].toObject()["parts"].toArray()[0].toObject()["text"].toString();

        QJsonArray dataArray = QJsonDocument::fromJson(contentStr.toUtf8()).array();

        for (const QJsonValue &value : dataArray) {
            QJsonObject item = value.toObject();
            QString type = item["type"].toString();
            double amount = item["amount"].toDouble();
            QString desc = item["description"].toString();

            QString currentTime = QDateTime::currentDateTime().toString("MMM dd, yyyy - hh:mm AP");

            if (type == "income") balance += amount;
            else if (type == "expense") balance -= amount;

            // Save balance to phone storage
            QSettings settings("ZayanDev", "MyFinanceAI");
            settings.setValue("savedBalance", balance);

            emit transactionAdded(type, amount, desc, currentTime);
        }

        emit balanceChanged();
    } else {
        emit apiError("Network Error or Bad API Key");
    }
    reply->deleteLater();
}