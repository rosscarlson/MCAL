using System.Windows;
using MCAL.Theming;

namespace MCAL;

public partial class App : Application
{
    private static Mutex? singleInstance;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        DispatcherUnhandledException += (_, args) =>
        {
            MessageBox.Show(args.Exception.Message, "Multi Channel Audio Leveler", MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
        };

        // Single instance: a second launch just brings the running one to the front.
        singleInstance = new Mutex(true, @"Local\MCAL.SingleInstance", out bool first);
        bool exitRequest = e.Args.Contains("--exit", StringComparer.OrdinalIgnoreCase);
        if (!first)
        {
            // "MCAL.exe --exit" closes the running instance cleanly (used by the uninstaller); otherwise bring it forward.
            try { using var signal = EventWaitHandle.OpenExisting(exitRequest ? @"Local\MCAL.Exit" : @"Local\MCAL.Show"); signal.Set(); } catch { }
            Shutdown();
            return;
        }
        if (exitRequest)
        {
            Shutdown();
            return;
        }

        var settings = AppSettings.Load();
        ThemeManager.Apply(settings.Theme);

        var window = new MainWindow(settings);
        MainWindow = window;
        if (e.Args.Contains("--tray", StringComparer.OrdinalIgnoreCase)) window.StartInTray();
        else window.Show();

        var showEvent = new EventWaitHandle(false, EventResetMode.AutoReset, @"Local\MCAL.Show");
        var exitEvent = new EventWaitHandle(false, EventResetMode.AutoReset, @"Local\MCAL.Exit");
        new Thread(() =>
        {
            var handles = new WaitHandle[] { showEvent, exitEvent };
            while (true)
            {
                if (WaitHandle.WaitAny(handles) == 0) Dispatcher.BeginInvoke(window.ShowFromTray);
                else Dispatcher.BeginInvoke(window.ExitApp);
            }
        }) { IsBackground = true, Name = "MCAL instance listener" }.Start();

        // Restart Manager (installer / auto-update) and Windows shutdown must be able to close the app.
        SessionEnding += (_, _) => window.PrepareForSessionEnd();
    }
}
