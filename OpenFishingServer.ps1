$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class WinSqliteNative
{
    private const int SQLITE_OK = 0;
    private const int SQLITE_ROW = 100;
    private const int SQLITE_DONE = 101;

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_open")]
    private static extern int sqlite3_open(byte[] filename, out IntPtr database);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_close")]
    private static extern int sqlite3_close(IntPtr database);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_exec")]
    private static extern int sqlite3_exec(IntPtr database, byte[] sql, IntPtr callback, IntPtr argument, out IntPtr errorMessage);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_free")]
    private static extern void sqlite3_free(IntPtr memory);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_prepare_v2")]
    private static extern int sqlite3_prepare_v2(IntPtr database, byte[] sql, int byteCount, out IntPtr statement, IntPtr tail);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_bind_text")]
    private static extern int sqlite3_bind_text(IntPtr statement, int index, byte[] value, int byteCount, IntPtr destructor);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_step")]
    private static extern int sqlite3_step(IntPtr statement);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_finalize")]
    private static extern int sqlite3_finalize(IntPtr statement);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_column_text")]
    private static extern IntPtr sqlite3_column_text(IntPtr statement, int column);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_column_bytes")]
    private static extern int sqlite3_column_bytes(IntPtr statement, int column);

    [DllImport("winsqlite3.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "sqlite3_errmsg")]
    private static extern IntPtr sqlite3_errmsg(IntPtr database);

    private static byte[] Utf8NullTerminated(string value)
    {
        byte[] text = Encoding.UTF8.GetBytes(value);
        Array.Resize(ref text, text.Length + 1);
        return text;
    }

    private static string ReadUtf8(IntPtr value, int length)
    {
        if (value == IntPtr.Zero || length <= 0) return String.Empty;
        byte[] text = new byte[length];
        Marshal.Copy(value, text, 0, length);
        return Encoding.UTF8.GetString(text);
    }

    private static string ReadCString(IntPtr value)
    {
        if (value == IntPtr.Zero) return String.Empty;
        int length = 0;
        while (Marshal.ReadByte(value, length) != 0) length++;
        return ReadUtf8(value, length);
    }

    private static void Check(IntPtr database, int result)
    {
        if (result != SQLITE_OK)
            throw new InvalidOperationException(ReadCString(sqlite3_errmsg(database)));
    }

    public static IntPtr Open(string path)
    {
        IntPtr database;
        int result = sqlite3_open(Utf8NullTerminated(path), out database);
        if (result != SQLITE_OK)
        {
            string message = database == IntPtr.Zero ? "Could not open the SQLite database." : ReadCString(sqlite3_errmsg(database));
            if (database != IntPtr.Zero) sqlite3_close(database);
            throw new InvalidOperationException(message);
        }
        return database;
    }

    public static void Initialize(IntPtr database)
    {
        string sql = "CREATE TABLE IF NOT EXISTS app_state (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);";
        IntPtr errorMessage;
        int result = sqlite3_exec(database, Utf8NullTerminated(sql), IntPtr.Zero, IntPtr.Zero, out errorMessage);
        if (result != SQLITE_OK)
        {
            string message = ReadCString(errorMessage);
            if (errorMessage != IntPtr.Zero) sqlite3_free(errorMessage);
            throw new InvalidOperationException(message);
        }
    }

    public static Dictionary<string, string> ReadAll(IntPtr database)
    {
        string sql = "SELECT key, value FROM app_state ORDER BY key;";
        byte[] query = Utf8NullTerminated(sql);
        IntPtr statement;
        Check(database, sqlite3_prepare_v2(database, query, query.Length - 1, out statement, IntPtr.Zero));
        try
        {
            Dictionary<string, string> values = new Dictionary<string, string>();
            while (true)
            {
                int result = sqlite3_step(statement);
                if (result == SQLITE_DONE) break;
                if (result != SQLITE_ROW) Check(database, result);
                values[ReadUtf8(sqlite3_column_text(statement, 0), sqlite3_column_bytes(statement, 0))] =
                    ReadUtf8(sqlite3_column_text(statement, 1), sqlite3_column_bytes(statement, 1));
            }
            return values;
        }
        finally
        {
            sqlite3_finalize(statement);
        }
    }

    public static void Set(IntPtr database, string key, string value)
    {
        string sql = "INSERT INTO app_state (key, value, updated_at) VALUES (?1, ?2, CURRENT_TIMESTAMP) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP;";
        byte[] query = Utf8NullTerminated(sql);
        IntPtr statement;
        Check(database, sqlite3_prepare_v2(database, query, query.Length - 1, out statement, IntPtr.Zero));
        try
        {
            byte[] keyBytes = Encoding.UTF8.GetBytes(key);
            byte[] valueBytes = Encoding.UTF8.GetBytes(value);
            Check(database, sqlite3_bind_text(statement, 1, keyBytes, keyBytes.Length, new IntPtr(-1)));
            Check(database, sqlite3_bind_text(statement, 2, valueBytes, valueBytes.Length, new IntPtr(-1)));
            int result = sqlite3_step(statement);
            if (result != SQLITE_DONE) Check(database, result);
        }
        finally
        {
            sqlite3_finalize(statement);
        }
    }

    public static void Close(IntPtr database)
    {
        if (database != IntPtr.Zero) sqlite3_close(database);
    }
}
'@

$port = 8765
$root = $PSScriptRoot
$databasePath = Join-Path $root "open-fishing.sqlite3"
$allowedKeys = @(
    "castaway-profile",
    "castaway-catches",
    "castaway-events",
    "castaway-joined",
    "castaway-destination"
)
$database = [WinSqliteNative]::Open($databasePath)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")

function Send-Response($Context, [int]$StatusCode, [string]$ContentType, [byte[]]$Body) {
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = $ContentType
    $Context.Response.ContentEncoding = [System.Text.Encoding]::UTF8
    $Context.Response.ContentLength64 = $Body.Length
    $Context.Response.OutputStream.Write($Body, 0, $Body.Length)
    $Context.Response.Close()
}

function Send-Json($Context, [int]$StatusCode, [string]$Body) {
    Send-Response $Context $StatusCode "application/json; charset=utf-8" ([System.Text.Encoding]::UTF8.GetBytes($Body))
}

function Get-MimeType([string]$Path) {
    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".html" { return "text/html; charset=utf-8" }
        ".js" { return "text/javascript; charset=utf-8" }
        ".png" { return "image/png" }
        default { return "application/octet-stream" }
    }
}

try {
    [WinSqliteNative]::Initialize($database)
    $listener.Start()
    Write-Host "Open Fishing is running at http://127.0.0.1:$port/"
    Write-Host "SQLite database: $databasePath"
    Write-Host "Keep this window open while using the app. Press Ctrl+C to stop."
    Start-Process "http://127.0.0.1:$port/"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $method = $context.Request.HttpMethod
            $path = $context.Request.Url.AbsolutePath

            if ($path -eq "/api/state" -and $method -eq "GET") {
                $values = [WinSqliteNative]::ReadAll($database)
                $entries = New-Object System.Collections.Generic.List[string]
                foreach ($key in $allowedKeys) {
                    if ($values.ContainsKey($key)) {
                        $entries.Add(('"{0}":{1}' -f $key, $values[$key]))
                    }
                }
                Send-Json $context 200 ("{" + [string]::Join(",", $entries) + "}")
                continue
            }

            if ($path.StartsWith("/api/state/") -and $method -eq "PUT") {
                $key = [System.Uri]::UnescapeDataString($path.Substring("/api/state/".Length))
                if ($key -notin $allowedKeys) {
                    Send-Json $context 404 '{"error":"Unknown app data key."}'
                    continue
                }
                if ($context.Request.ContentLength64 -gt 128MB) {
                    Send-Json $context 413 '{"error":"The submitted data is too large."}'
                    continue
                }
                $reader = New-Object System.IO.StreamReader($context.Request.InputStream, [System.Text.Encoding]::UTF8)
                $json = $reader.ReadToEnd()
                $reader.Dispose()
                try {
                    $null = ConvertFrom-Json -InputObject $json -ErrorAction Stop
                } catch {
                    Send-Json $context 400 '{"error":"The request body must contain valid JSON."}'
                    continue
                }
                [WinSqliteNative]::Set($database, $key, $json)
                Send-Json $context 200 '{"saved":true}'
                continue
            }

            if ($method -ne "GET" -and $method -ne "HEAD") {
                Send-Json $context 405 '{"error":"Method not allowed."}'
                continue
            }

            $relativePath = switch ($path) {
                "/" { "index.html"; break }
                "/index.html" { "index.html"; break }
                "/earth-data.js" { "earth-data.js"; break }
                "/fishing-scene-photo.png" { "fishing-scene-photo.png"; break }
                default { $null }
            }
            if (-not $relativePath) {
                Send-Json $context 404 '{"error":"Not found."}'
                continue
            }
            $filePath = Join-Path $root $relativePath
            if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                Send-Json $context 404 '{"error":"App asset not found."}'
                continue
            }
            $body = [System.IO.File]::ReadAllBytes($filePath)
            if ($method -eq "HEAD") { $body = [byte[]]@() }
            Send-Response $context 200 (Get-MimeType $filePath) $body
        } catch {
            Write-Warning "Request failed: $($_.Exception.Message)"
            try {
                Send-Json $context 500 '{"error":"The local app server could not complete the request."}'
            } catch {
                Write-Warning "Could not send the error response: $($_.Exception.Message)"
            }
        }
    }
} finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
    [WinSqliteNative]::Close($database)
}
