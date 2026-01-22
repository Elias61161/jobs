-- Parser module
Parser = {}

-- Check if field has correct type
local function checkFieldType(value, expectedType, optional)
    if not value then
        return optional
    end
    return type(value) == expectedType
end

-- Validate job data structure
local function validateJobData(jobData)
    if not checkFieldType(jobData.name, "string", false) then
        return false, "the name field needs to be a valid string."
    end

    if not checkFieldType(jobData.label, "string", false) then
        return false, "the label field needs to be a valid string."
    end

    if not checkFieldType(jobData.grades, "table", false) then
        return false, "provide valid grades in an array."
    end

    if not checkFieldType(jobData.blips, "table", true) then
        return false, "provide valid blips data in an array."
    end

    if not checkFieldType(jobData.cloakrooms, "table", true) then
        return false, "provide valid cloakrooms table."
    end

    if not checkFieldType(jobData.collecting, "table", true) then
        return false, "provide valid collecting data in an array."
    end

    if not checkFieldType(jobData.crafting, "table", true) then
        return false, "provide valid crafting data in an array."
    end

    if not checkFieldType(jobData.garages, "table", true) then
        return false, "provide valid garage data in an array."
    end

    if not checkFieldType(jobData.selling, "table", true) then
        return false, "provide valid selling data in an array."
    end

    if not checkFieldType(jobData.shops, "table", true) then
        return false, "provide valid shops in an array."
    end

    if not checkFieldType(jobData.stashes, "table", true) then
        return false, "provide valid stashes in an array."
    end

    return true
end

-- Check if resource is started
local function isResourceStarted(resourceName)
    return GetResourceState(resourceName) == "started"
end

-- Validate annotation structure
local function validateAnnotations(content)
    local state = nil

    for line in content:gmatch("[^\n]+") do
        local hasIfResource = line:find("---@if_resource") or line:find("---@if_not_resource")

        if hasIfResource then
            if state then
                print("Invalid: " .. line)
                return false
            end

            local resourceName = line:match("%((.-)%)")
            if not resourceName then
                print("Invalid: " .. line)
                return false
            end

            state = "if_resource"
        else
            local hasElseif = line:find("---@elseif_resource") or line:find("---@elseif_not_resource")

            if hasElseif then
                if state ~= "if_resource" and state ~= "elseif_resource" then
                    return false
                end

                local resourceName = line:match("%((.-)%)")
                if not resourceName then
                    return false
                end

                state = "elseif_resource"
            elseif line:find("---@else") then
                if state ~= "if_resource" and state ~= "elseif_resource" then
                    return false
                end

                local resourceName = line:match("%((.-)%)")
                if resourceName then
                    return false
                end

                state = "else"
            elseif line:find("---@end") then
                if not state then
                    return false
                end

                local resourceName = line:match("%((.-)%)")
                if resourceName then
                    return false
                end

                state = nil
            end
        end
    end

    return state == nil
end

-- Process conditional annotations
local function processAnnotations(content)
    if not validateAnnotations(content) then
        return nil
    end

    local result = ""
    local state = "reading"

    for line in content:gmatch("[^\n]+") do
        if line:find("---@if_resource") and state == "reading" then
            local resourceName = line:match("%((.-)%)")
            if isResourceStarted(resourceName) then
                state = "reading_to_end"
            else
                state = "skipping"
            end
        elseif line:find("---@if_not_resource") and state == "reading" then
            local resourceName = line:match("%((.-)%)")
            if isResourceStarted(resourceName) then
                state = "skipping"
            else
                state = "reading_to_end"
            end
        elseif line:find("---@elseif_resource") then
            if state == "skipping" then
                local resourceName = line:match("%((.-)%)")
                if isResourceStarted(resourceName) then
                    state = "reading_to_end"
                end
            elseif state == "reading_to_end" then
                state = "skipping_to_end"
            end
        elseif line:find("---@elseif_not_resource") then
            if state == "skipping" then
                local resourceName = line:match("%((.-)%)")
                if not isResourceStarted(resourceName) then
                    state = "reading_to_end"
                end
            elseif state == "reading_to_end" then
                state = "skipping_to_end"
            end
        elseif line:find("---@else") then
            if state == "skipping" then
                state = "reading_to_end"
            else
                state = "skipping"
            end
        elseif line:find("---@end") then
            if state == "skipping" or state == "reading_to_end" or state == "skipping_to_end" then
                state = "reading"
            end
        elseif state == "reading" or state == "reading_to_end" then
            result = result .. "\n" .. line
        end
    end

    return result
end

-- Parse job file content
function Parser.parse(content)
    local processedContent = processAnnotations(content)
    local codeToLoad = processedContent or content

    local loadedFunc, loadError = load(codeToLoad)

    if not loadedFunc then
        return false, "Couldn't load %s due to a syntax error: " .. loadError
    end

    local jobData = loadedFunc()

    if not jobData then
        return false, "Couldn't load %s due to no return statement."
    end

    local isValid, validationError = validateJobData(jobData)

    if isValid then
        if not processedContent then
            warn(("Ignoring annotations in job %s."):format(jobData.name))
        end
        return true, jobData
    else
        return false, "Couldn't load %s due to invalid data: " .. validationError
    end
end
