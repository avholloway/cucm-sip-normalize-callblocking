--[[
  If we are performing call blocking based on calling number, and we receive
  an INVITE from anonymous, it will be blocked because, CUCM will not be able
  to use our blank nor ! XLATEs we use to permit non-blacklisted callers.

  Therefore, we are going to find and replace these anonymous caller IDs with
  a known numeric caller ID, for the purposes of matching our ! XLATE to permit
  the call through our call blocking construct.

  E.g.,
  sip:anonymous@1.1.1.1 becomes sip:1111111111@1.1.1.1

  Anthony Holloway (avholloway@gmail.com)
  December 2019
--]]

M = {}

-- Enable tracing if you are troubleshooting
trace.enable()

-- It all starts with receiving a call
function M.inbound_INVITE(msg)
  trace.format("CALL_BLOCKING: Handler: inbound_INVITE")
  trace.format("CALL_BLOCKING: Inspecting From: "..from_header)

  -- The From header needs to be present and cannot contain a digit in LHS
  -- This allows us to quit our app as fast as possible, since this will be
  -- executed for every call, but the percentage of matches will be very low
  local from_header = msg:getHeader("From")
  if not from_header or from_header:find("%d@") then
    trace.format("CALL_BLOCKING: Exiting due to numeric value in LHS")
    return
  end

  -- The following caller ID values will trigger a replacement
  -- We match the LHS of the SIP URI, and not the Calling Name in quotes
  local caller_ids = {"anonymous", "restricted", "unavailable"}

  -- Does our From header match one of our caller ID values?
  if not find_one(from_header, caller_ids) then
    trace.format("CALL_BLOCKING: Exiting due to no match with our caller IDs")
    return
  end

  -- We'll use the dialog context to flag calls we've modified, store
  -- information about the call, and to restore original values when needed
  local context = msg:getContext()
  if not context then
    trace.format("CALL_BLOCKING: Exiting due to missing context for dialog")
    return
  end

  -- Our flag in the context of this dialog so we can check further messages
  -- within this dialog and know it's our special type of call versus some
  -- other random call.
  context.anonymous = true

  -- And we'll store the replacement to the LHS
  context.replacement = "1111111111"

  -- The following Headers will be checked and replaced
  local headers = {"From", "Remote-Party-ID", "Contact",
    "P-Preferred-Identity", "P-Asserted-Identity"}

  -- Check each header in our list one-by-one, to perform the fix on it
  for _, header in pairs(headers) do

    -- Try to grab this header, if its not present, just move to the next header
    local value = msg:getHeader(header)
    if not value then break end
    trace.format("CALL_BLOCKING: Pre-Change: "..header..": "..value)

    -- If this header contains one of our caller ID keywords
    if find_one(value, caller_ids) then

        -- Store the original value for later
        context[header] = value

        -- Perform the swap to the new value
        value = value:gsub(":.+@", ":"..replacement.."@")
        msg:modifyHeader(header, value)
        trace.format("CALL_BLOCKING: Post-Change: "..header..": "..value)
    end
  end

end

-- Takes a string and a table of patterns and returns true or false if one
-- of the patterns matches the string
local function find_one(s, t)
  for _, v in pairs(t) do
    if s:lower():find(":"..v.."@") then return true end
  end
  return false
end

return M
