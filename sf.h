#ifndef SF_H
#define SF_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QDateTime>
#include <QSettings>

class StudentFinance : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentBalance READ getCurrentBalance NOTIFY balanceChanged)

public:
    explicit StudentFinance(QObject *parent = nullptr);

    Q_INVOKABLE void processInput(const QString &userInput);
    Q_INVOKABLE void setApiKey(const QString &key);
    Q_INVOKABLE QString getApiKey();
    Q_INVOKABLE void deleteTransaction(QString type, double amount);

    QString getCurrentBalance() const;

signals:
    void balanceChanged();
    void transactionAdded(QString type, double amount, QString desc, QString time);
    void apiError(QString errorMsg);

private slots:
    void onApiReply(QNetworkReply *reply);

private:
    QNetworkAccessManager *networkManager;
    QString apiKey;
    double balance;
};

#endif // SF_H