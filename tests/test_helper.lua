-- Tiny dependency-free runner shared by every suite.
local test = { passed = 0, failed = 0 }

function test.equal(actual, expected, description)
    if actual ~= expected then
        error((description or "Values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

function test.case(name, run)
    local succeeded, message = xpcall(run, debug.traceback)
    if succeeded then
        test.passed = test.passed + 1
        print("  PASS " .. name)
    else
        test.failed = test.failed + 1
        print("  FAIL " .. name .. "\n" .. message)
    end
end

return test
