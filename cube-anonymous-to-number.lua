--[[
  If we are performing call blocking based on calling number, and we receive
  an INVITE from anonymous, it will be blocked because, CUCM will not be able
  to use our blank nor ! XLATEs to permit calls.

  Therefore, we are going to find and replace these anonymous caller IDs with
  a known numeric caller ID, for the purposes of matching our ! XLATE to permit
  the call through our call blocking construct.

  Anthony Holloway (avholloway@gmail.com)
--]]

M = {}

-- It all starts with receiving a call
function M.inbound_INVITE(msg)

  -- If the From header has digits in its value, then this aint our guy
  -- From: "Anthony Holloway" <sip:+16125551212@1.1.1.1>;tag=ABC
  -- From: "Anonymous" <sip:anonymous@1.1.1.1>;tag=ABC
  local from_header = msg:getHeader("From")
  if not from_header or string.find(from_header, "%d@") then return end

  -- We'll use the dialog context to flag calls we've modified, store
  -- information about the call, and to restore original values when needed
  local context = msg:getContext()
  if not context then return end

end

return M
