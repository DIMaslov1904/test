script_name('ToolsMate[AdBlock]')
script_author('DIMaslov1904')
script_version("1.0.0")
script_url("https://t.me/ToolsMate")
script_description('���������� ������ � ��� ��������� ���������.')


-- �����������
local isSampev, sampev = pcall(require, 'samp.events')

if not isSampev then
  sampAddChatMessage(script.this.name..' ��������. ���������� [SAMP.Lua] �� �����������!', 0xD87093)
  thisScript():unload()
  return
end


-- ����������
local toggle = true
local messages = {
  '����������:',
  '�������� News',
  '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
  '������� ��� ������ � ��������� ������� - /ask',
  '��� ������������ ��� ���������� �� ������ �������� �� ����� - samp-rp.ru',
  '������� ������ � ������� �� ������������ ����� Samp RolePlay - /music',
}


-- �������
local function ads()
  local isNotify, notify = pcall(import, ('ToolsMate'))
  if toggle==true then
    toggle=false
    if isNotify then notify.addNotify( "{FF0000}AdBlock. ���������� ���������!", 5)
    else sampAddChatMessage('AdBlock. ���������� ���������!', 0xFF0000) end
  else
    toggle=true
    if isNotify then notify.addNotify("{00FF00}AdBlock. ���������� ��������!", 5)
    else sampAddChatMessage('AdBlock. ���������� ��������!', 0x00FF00) end
  end
end


-- ����
function main()
  EXPORTS.TAG_ADDONS = 'ToolsMate'
  EXPORTS.NAME_ADDONS = 'AdBlock'
  EXPORTS.run = ads

  if not isSampLoaded() or not isSampfuncsLoaded() then return end
  while not isSampAvailable() do wait(0) end
  function sampev.onServerMessage(_, text)
    if toggle==true then
      for _, mess in ipairs(messages) do
        if text:match('^'..mess) then
          return false
        end
        -- if  string.find (text,mess,1,true) then
        --   return false
        -- end
      end
    end
  end
  sampRegisterChatCommand("adb", ads)
end
