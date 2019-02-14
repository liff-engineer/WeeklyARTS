#include "MainWindow.hpp"

MainWindow::MainWindow(QWidget *parent, Qt::WindowFlags flags)
    : QMainWindow(parent, flags)
{
    setWindowTitle(QString::fromWCharArray(L"Qt与CMake"));
}