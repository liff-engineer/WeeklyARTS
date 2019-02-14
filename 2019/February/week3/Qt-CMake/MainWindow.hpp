#pragma once

#include <QtWidgets/QMainWindow>

class MainWindow : public QMainWindow
{
    Q_OBJECT
  public:
    explicit MainWindow(QWidget *parent = nullptr, Qt::WindowFlags flags = 0);
    ~MainWindow() = default;
};