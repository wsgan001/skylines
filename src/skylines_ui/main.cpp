#include "main_window.hpp"
#include <QApplication>

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);
    sl::ui::MainWindow w;
    w.show();

    return a.exec();
}
