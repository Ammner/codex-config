using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;

internal static class NimbalystCc3pLauncher
{
    private static int Main(string[] args)
    {
        try
        {
            var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            var secretFile = Environment.GetEnvironmentVariable("CC3P_SECRET_FILE");
            if (String.IsNullOrWhiteSpace(secretFile))
                secretFile = Path.Combine(home, ".hermes", "secrets", "third-party.env");

            var values = ReadEnvFile(secretFile);
            string token;
            if (!values.TryGetValue("THIRD_PARTY_AUTH_TOKEN", out token) || String.IsNullOrWhiteSpace(token))
                return Fail("THIRD_PARTY_AUTH_TOKEN is missing from " + secretFile);

            string baseUrl;
            if (!values.TryGetValue("THIRD_PARTY_BASE_URL", out baseUrl) || String.IsNullOrWhiteSpace(baseUrl))
                baseUrl = "https://www.claudecodeserver.top/api";

            Uri parsed;
            if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out parsed) ||
                (parsed.Scheme != Uri.UriSchemeHttp && parsed.Scheme != Uri.UriSchemeHttps))
                return Fail("THIRD_PARTY_BASE_URL must be an absolute http(s) URL");

            var claude = ResolveClaudeBinary();
            if (claude == null)
                return Fail("Claude Code native binary was not found. Set NIMBALYST_CC3P_CLAUDE_BINARY to its full path.");

            Environment.SetEnvironmentVariable("ANTHROPIC_BASE_URL", baseUrl);
            Environment.SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", token);
            foreach (var name in new[] {
                "ANTHROPIC_API_KEY", "ANTHROPIC_MODEL", "ANTHROPIC_DEFAULT_OPUS_MODEL",
                "ANTHROPIC_DEFAULT_SONNET_MODEL", "ANTHROPIC_DEFAULT_HAIKU_MODEL",
                "CLAUDE_CODE_SUBAGENT_MODEL"
            }) Environment.SetEnvironmentVariable(name, null);

            var start = new ProcessStartInfo
            {
                FileName = claude,
                Arguments = String.Join(" ", args.Select(QuoteWindowsArgument)),
                UseShellExecute = false,
                CreateNoWindow = false,
                WorkingDirectory = Environment.CurrentDirectory
            };
            using (var child = Process.Start(start))
            {
                if (child == null) return Fail("Failed to start Claude Code");
                child.WaitForExit();
                return child.ExitCode;
            }
        }
        catch (Exception ex)
        {
            return Fail(ex.Message);
        }
    }

    private static Dictionary<string, string> ReadEnvFile(string path)
    {
        if (!File.Exists(path)) throw new FileNotFoundException("CC 3P secret file not found", path);
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var raw in File.ReadAllLines(path))
        {
            var line = raw.Trim();
            if (line.Length == 0 || line.StartsWith("#")) continue;
            var equals = line.IndexOf('=');
            if (equals <= 0) continue;
            var key = line.Substring(0, equals).Trim();
            var value = line.Substring(equals + 1).Trim();
            if (value.Length >= 2 && ((value[0] == '"' && value[value.Length - 1] == '"') ||
                                      (value[0] == '\'' && value[value.Length - 1] == '\'')))
                value = value.Substring(1, value.Length - 2);
            result[key] = value;
        }
        return result;
    }

    private static string ResolveClaudeBinary()
    {
        var explicitPath = Environment.GetEnvironmentVariable("NIMBALYST_CC3P_CLAUDE_BINARY");
        if (!String.IsNullOrWhiteSpace(explicitPath) && File.Exists(explicitPath))
            return Path.GetFullPath(explicitPath);

        var self = Path.GetFullPath(Assembly.GetExecutingAssembly().Location);
        var candidates = new List<string>();
        var local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var winget = Path.Combine(local, "Microsoft", "WinGet", "Packages");
        if (Directory.Exists(winget))
            candidates.AddRange(Directory.GetDirectories(winget, "Anthropic.ClaudeCode_*")
                .Select(dir => Path.Combine(dir, "claude.exe")));

        var path = Environment.GetEnvironmentVariable("PATH") ?? "";
        candidates.AddRange(path.Split(Path.PathSeparator)
            .Where(part => !String.IsNullOrWhiteSpace(part))
            .Select(part => Path.Combine(part.Trim().Trim('"'), "claude.exe")));

        return candidates.FirstOrDefault(candidate =>
            File.Exists(candidate) && !String.Equals(Path.GetFullPath(candidate), self, StringComparison.OrdinalIgnoreCase));
    }

    private static string QuoteWindowsArgument(string value)
    {
        if (value.Length > 0 && value.All(ch => !Char.IsWhiteSpace(ch) && ch != '"')) return value;
        var result = new StringBuilder("\"");
        var slashes = 0;
        foreach (var ch in value)
        {
            if (ch == '\\') { slashes++; continue; }
            if (ch == '"') result.Append('\\', slashes * 2 + 1).Append(ch);
            else { result.Append('\\', slashes).Append(ch); }
            slashes = 0;
        }
        result.Append('\\', slashes * 2).Append('"');
        return result.ToString();
    }

    private static int Fail(string message)
    {
        Console.Error.WriteLine("nimbalyst-cc3p: " + message);
        return 1;
    }
}
