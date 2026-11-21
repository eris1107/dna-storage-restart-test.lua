-- DNA STORAGE RESTART TEST V2 ONLY.
-- No HTTP, tokens, catch listener, or production outbox access.
-- CHECK never creates, overwrites or deletes the test file.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local FILE = "dna_restart_probe_v2.json"
local MARKER = "DNA_RESTART_PROBE_V2"
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")
local previous = parent:FindFirstChild("DNARestartStorageProbeV2")
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DNARestartStorageProbeV2"
gui.ResetOnSpawn = false
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.9, 0, 0, 310)
frame.Position = UDim2.new(0.05, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 29, 48)
frame.Parent = gui
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 180)
status.Position = UDim2.fromOffset(12, 12)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(225, 245, 240)
status.TextSize = 16
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = frame
local function report(text)
    status.Text = text
    print("DNA_RESTART_TEST: " .. text)
end
local function support()
    assert(type(isfile) == "function", "isfile tidak tersedia")
    assert(type(readfile) == "function", "readfile tidak tersedia")
    assert(type(writefile) == "function", "writefile tidak tersedia")
end
local function verify(value)
    assert(type(value) == "table" and value.marker == MARKER, "Identitas file uji tidak cocok")
    assert(type(value.run_id) == "string" and #value.run_id > 10, "Kode percobaan tidak valid")
    assert(type(value.jobs) == "table" and #value.jobs == 3, "Jumlah entri tidak cocok")
    for i = 1, 3 do
        assert(type(value.jobs[i]) == "table", "Entri rusak")
        assert(value.jobs[i].event_id == value.run_id .. "-" .. i, "ID entri berubah")
        assert(value.jobs[i].score == 10 * i, "Nilai entri berubah")
    end
    return value
end
local function readExisting()
    support()
    assert(isfile(FILE), "FILE TIDAK DITEMUKAN. Pemeriksaan tidak membuat file baru.")
    return verify(HttpService:JSONDecode(readfile(FILE)))
end
local busy = false
local function button(text, y, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -24, 0, 30)
    b.Position = UDim2.fromOffset(12, y)
    b.Text = text
    b.TextSize = 14
    b.Parent = frame
    b.Activated:Connect(function()
        if busy then return end
        busy = true
        local ok, err = pcall(fn)
        if not ok then report("TES BELUM LOLOS\n" .. tostring(err):sub(1, 320)) end
        busy = false
    end)
end
button("1. Simpan sebelum restart", 200, function()
    support()
    if isfile(FILE) then
        local value = readExisting()
        report("FILE LAMA TETAP DISIMPAN, TIDAK DITIMPA\nKode: " .. value.run_id
            .. "\nAmbil screenshot kode ini. Jika sudah restart, gunakan tombol 2. Tidak ada file yang dihapus.")
        return
    end
    local id = HttpService:GenerateGUID(false)
    local value = {marker = MARKER, run_id = id, created = os.time(), jobs = {}}
    for i = 1, 3 do
        table.insert(value.jobs, {event_id = id .. "-" .. i, score = 10 * i})
    end
    local encoded = HttpService:JSONEncode(value)
    writefile(FILE, encoded)
    assert(readfile(FILE) == encoded, "Verifikasi tulis file gagal")
    verify(HttpService:JSONDecode(readfile(FILE)))
    report("TERSIMPAN: 3 ENTRI\nKode: " .. id
        .. "\nAmbil screenshot. Tutup Roblox sepenuhnya, buka lagi, jalankan skrip yang sama, lalu tekan tombol 2, BUKAN tombol 1.")
end)
button("2. Periksa setelah restart (hanya membaca)", 236, function()
    local value = readExisting()
    report("FILE TERBACA: 3 ENTRI DAN NILAI SESUAI\nKode: " .. value.run_id
        .. "\nBandingkan dengan screenshot sebelum restart. Tes restart hanya lolos jika aplikasi benar-benar sudah ditutup dan kodenya sama. File tidak dihapus.")
end)
button("Tutup panel (file tetap disimpan)", 272, function()
    gui:Destroy()
end)
report("TES PENYIMPANAN RESTART V2\nBelum ada file yang ditulis oleh eksekusi ini.\nSebelum restart: tekan tombol 1.\nSesudah restart: tekan tombol 2.\nTidak mengirim data ke DNA dan tidak menyentuh antrean logger.")
gui.Parent = parent
