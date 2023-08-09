script_name('ToolsMate[Updater]')
script_author('DIMaslov1904')
script_version("0.1.0")
script_url("https://t.me/ToolsMate")
script_description('Автообновление скриптов.')


-- Зависимости
local dlstatus = require('moonloader').download_status


-- Переменные
local comamnd = 'updater'
local update_path = getWorkingDirectory() .. '\\' .. comamnd .. '\\'
local is_updates = false  -- есть ли обновления
local state = {
    autoCheck = false,    -- Авто проверка
    autoDownload = false, -- Авто обновление
    unload = false,       -- Выгружаться после проверки
    libs = {},            -- Список всех скриптов
    urlsCheck = {}        -- Ссылки на проверку обновлений
}
local color = {
    successes = 0xCED23A,
    warning = 0xFFB841,
    errors = 0xD87093,
}


-- Функции
local f = string.format

local function json(directory)
    local class = {}
    function class:Save(tbl)
        if tbl then
            local F = io.open(directory, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end

    function class:Load(default_table)
        local default_table = default_table or {}
        if not doesFileExist(directory) then class:Save(default_table or {}) end
        local F = io.open(directory, "r")
        local TABLE = decodeJson(F:read("*a") or {})
        F:close()
        return TABLE
    end

    return class
end

local function browseScripts()
    state.libs = {}
    state.urlsCheck = {}

    for _, s in pairs(script.list()) do
        table.insert(state.libs, {
            name = s.name,
            version = s.version or '0.1.0',
            path = s.path,
            urlCheckUpdate = s.exports and s.exports.URL_CHECK_UPDATE or nil,
            urlGetUpdate = s.exports and s.exports.URL_GET_UPDATE or nil,
            tag = s.exports and s.exports.TAG_ADDONS or nil
        })
        if (s.exports and s.exports.URL_CHECK_UPDATE) then
            if (s.exports.TAG_ADDONS and not state.urlsCheck[s.exports.TAG_ADDONS]) then
                state.urlsCheck[s.exports.TAG_ADDONS] = {
                    url = s.exports.URL_CHECK_UPDATE
                }
            elseif not s.exports.TAG_ADDONS then
                state.urlsCheck[s.name] = s.exports.URL_CHECK_UPDATE
            end
        end
    end
end

local function get(libName)
    print('Идёт скачивание обновлений...')
end

local function requestCheck(name, url)
    local directory = update_path .. name .. '.json'

    downloadUrlToFile(url, directory, function(id, status)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            print(directory .. ' - Загрузка завершена.')
            local versions_json = json(directory):Load({})

            for lib_name, val in pairs(versions_json) do
                for _, lib in pairs(state.libs) do
                    if lib.name == lib_name and val.version ~= lib.version then
                        local text_message = lib_name ..
                        ' - вышла новая версия: ' .. val.version .. ' | Текущая: ' .. lib.version
                        print(text_message)
                        is_updates = true
                        if state.autoDownload then
                            get(lib_name)
                        else
                            sampAddChatMessage(text_message, color.warning)
                        end
                    end
                end
            end
        end
    end)
end

local function check(libName)
    print('Анализ установленных скриптов...')
    browseScripts()

    -- print('Все скрипты ['..#state.libs..']:')
    -- for _, lib in pairs(state.libs) do
    --     for key, val in pairs(lib) do
    --         print(key..': '..tostring(val))
    --     end
    --     print('-----------------')
    -- end

    -- print('Все файлы обновлений ['..#state.urlsCheck..']:')
    -- for key, url in pairs(state.urlsCheck) do
    --     print(key..': '..tostring(url))
    --     print()
    -- end

    print('Идёт прововерка обновлений...')
    lua_thread.create(function()
        local urls = state.urlsCheck
        local count = 0
        local i = 0
        for _ in pairs(urls) do count = count + 1 end

        for name, url in pairs(urls) do
            requestCheck(name, url)
            i = i + 1
        end

        while true do
            wait(2000)
            if i == count then
                print('Проверка завершена!')

                if is_updates then
                    if state.autoDownload then
                        print('Все доступные скрипты обновлены!')
                    else
                        sampAddChatMessage('Автообновление скриптов отключено',
                            color.warning)
                        sampAddChatMessage('Для обновления вышеуказанных скриптов, используйте:',
                            color.warning)
                        sampAddChatMessage(f('/%s get script_name', comamnd), color.warning)
                    end
                end
                is_updates = false
                break
            end
        end
    end)
end

local function handler(arg)
    local fn, lib
    for str in arg:gmatch("([^%s]+)") do
        if not fn then
            fn = str
        elseif not lib then
            lib = str
        else
            lib = lib .. ' ' .. str
        end
    end

    local handlers = {
        {
            arg = 'check',
            name = 'проверить обновления (опц. имя скрипта)',
            collback = check
        },
        {
            arg = 'get',
            help = 'script_name',
            name = 'обновить скрипт (название можно писать через пробел)',
            collback = get
        },
    }

    for _, hand in pairs(handlers) do
        if hand.arg == fn then
            return hand.collback(lib)
        end
    end
    for _, hand in pairs(handlers) do
        sampAddChatMessage(
            f('%s -> {FFCF40}/%s %s %s{FFFFFF} - %s', script.this.name, comamnd, hand.arg, hand.help, hand.name), -1)
    end
end

function main()
    EXPORTS.TAG_ADDONS = 'ToolsMate'
    EXPORTS.NAME_ADDONS = 'Обновление'
    EXPORTS.run = function() end

    if not os.rename(update_path, update_path) and createDirectory(update_path) then
        print('Каталог с версиями создан:\n' .. update_path)
    end


    sampRegisterChatCommand(comamnd, handler)
    if state.autoCheck then
        wait(120000) -- ждёт 2 минуты перед запуском
        check()
    end
    wait(-1)
end
