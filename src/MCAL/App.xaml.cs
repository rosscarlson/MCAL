using System.Windows;
using MCAL.Theming;

namespace MCAL;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        DispatcherUnhandledException += (_, args) =>
        {
            MessageBox.Show(args.Exception.Message, "Multi Channel Audio Leveler", MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
        };

        var settings = AppSettings.Load();
        ThemeManager.Apply(settings.Theme);

        var window = new MainWindow(settings);
        MainWindow = window;
        window.Show();
    }
}
