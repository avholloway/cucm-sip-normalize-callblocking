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

-- Enable tracing if you are troubleshooting
trace.enable()

-- It all starts with receiving a call
function M.inbound_INVITE(msg)
  trace.format("CALL_BLOCKING: Handler: inbound_INVITE")

  -- The following caller IDs will trigger our replacement
  local caller_id = {
    anonymous   = "[Aa][Nn][Oo][Nn][Yy][Mm][Oo][Uu][Ss]",
    restricted  = "[Rr][Ee][Ss][Tt][Rr][Ii][Cc][Tt][Ee][Dd]",
    unavailable = "[Uu][Nn][Aa][Vv][Aa][Ii][Ll][Aa][Bb][Ll][Ee]"
  }

  -- And we'll replace the LHS with the following numeric pattern
  local replacement = "1111111111"

  -- The From header needs to match one of the above caller IDs, else return
  local from_header = msg:getHeader("From")
  if not from_header or (
     not from_header:find(anonymous) and
     not from_header:find(restricted) and
     not from_header:find(unavailable)
  ) then return end
  trace.format("CALL_BLOCKING: From: "..from_header)

  -- We'll use the dialog context to flag calls we've modified, store
  -- information about the call, and to restore original values when needed
  local context = msg:getContext()
  if not context then return end
  context.anonymous = true

  -- The following Headers will be checked and replaced
  local headers = {"From", "Remote-Party-ID", "Contact",
    "P-Preferred-Identity", "P-Asserted-Identity"}

  -- Check each header in our list of headers to check
  for _, header in pairs(headers) do
    local value = msg:getHeader(header)
    if not value then break end

    trace.format("CALL_BLOCKING: PRE: "..header..": "..value)

    -- If the header contains one of our caller ID keywords
    if value:find(anonymous)
      or value:find(restricted)
      or value:find(unavailable) then

        -- Store the original value for later
        context[header] = value

        -- Perform the swap to the new value
        value = value:gsub(":.+@", ":"..replacement.."@")
        msg:modifyHeader(header, value)
        trace.format("CALL_BLOCKING: POST: "..header..": "..value)
    end
  end

end

return M
