local tactile = {}

tactile.joysticks = love.joystick.getJoysticks()
tactile.deadzone = 0.25

tactile.buttonDetectors = {}
tactile.axisDetectors = {}
tactile.buttons = {}
tactile.axes = {}

--general button detector class
function tactile.addButtonDetector()
  local detector = {}
  detector.down = false
  table.insert(tactile.buttonDetectors, detector)
  return detector
end

--detects if a keyboard key is down/pressed/released
function tactile.addKeyboardButtonDetector(key)
  assert(type(key) == 'string', 'key is not a KeyConstant')

  local detector = tactile.addButtonDetector()
  detector.key = key

  function detector:update()
    self.down = love.keyboard.isDown(self.key)
  end

  return detector
end

--detects if a mouse button is down/pressed/released
function tactile.addMouseButtonDetector(button)
  assert(type(button) == 'string', 'button is not a MouseConstant')

  local detector = tactile.addButtonDetector()
  detector.button = button

  function detector:update()
    self.down = love.mouse.isDown(self.button)
  end

  return detector
end

--detects if a gamepad button is down/pressed/released
function tactile.addGamepadButtonDetector(button, joystickNum)
  assert(type(button) == 'string', 'button is not a GamepadButton')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector()
  detector.button      = button
  detector.joystickNum = joystickNum

  function detector:update()
    if tactile.joysticks[self.joystickNum] then
      self.down = tactile.joysticks[self.joystickNum]:isGamepadDown(self.button)
    end
  end

  return detector
end

--detects if a joystick axis passes a certain threshold
function tactile.addAxisButtonDetector(axis, threshold, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local detector = tactile.addButtonDetector()
  detector.axis        = axis
  detector.threshold   = threshold
  detector.joystickNum = joystickNum

  function detector:update()
    if tactile.joysticks[self.joystickNum] then
      local axisValue = tactile.joysticks[self.joystickNum]:getGamepadAxis(axis)
      detector.down = (axisValue < 0) == (self.threshold < 0) and math.abs(axisValue) > math.abs(self.threshold)
    end
  end

  return detector
end

--removes a button detector
function tactile.removeButtonDetector(name)
  assert(name, 'name is nil')

  tactile.buttonDetectors[name] = nil
end

--holds detectors
function tactile.addButton(detectors)
  assert(type(detectors) == 'table', 'detectors is not a table')

  local button = {}
  button.detectors = detectors

  button.downPrevious = false
  button.down         = false

  function button:update()
    button.downPrevious = button.down
    button.down = false

    for k, v in pairs(button.detectors) do
      --trigger the button if any of the detectors are triggered
      if v.down then
        button.down = true
      end
    end

    button.pressed  = button.down and not button.downPrevious
    button.released = button.downPrevious and not button.down
  end

  table.insert(tactile.buttons, button)
  return button
end

--removes a button
function tactile.removeButton(name)
  assert(name, 'name is nil')

  tactile.buttons[name] = nil
end

--general axis detector
function tactile.addAxisDetector()
  local axisDetector = {}
  axisDetector.value = 0

  function axisDetector:getValue()
    if math.abs(self.value) > tactile.deadzone then
      return self.value
    else
      return 0
    end
  end

  function axisDetector:update() end

  table.insert(tactile.axisDetectors, axisDetector)
  return axisDetector
end

--joystick axis detector
function tactile.addAnalogAxisDetector(axis, joystickNum)
  assert(type(axis) == 'string', 'axis is not a GamepadAxis')
  assert(type(joystickNum) == 'number', 'joystickNum is not a number')

  local axisDetector = tactile.addAxisDetector()
  axisDetector.axis        = axis
  axisDetector.joystickNum = joystickNum

  function axisDetector:update()
    if tactile.joysticks[self.joystickNum] then
      self.value = tactile.joysticks[self.joystickNum]:getGamepadAxis(self.axis)
    end
  end

  return axisDetector
end

--keyboard axis detector
function tactile.addBinaryAxisDetector(negative, positive)
  assert(negative, 'negative is nil')
  assert(positive, 'positive is nil')

  local axisDetector = tactile.addAxisDetector()
  axisDetector.negative = negative
  axisDetector.positive = positive

  function axisDetector:update()
    if self.negative.down and self.positive.down then
      self.value = 0
    elseif self.negative.down then
      self.value = -1
    elseif self.positive.down then
      self.value = 1
    else
      self.value = 0
    end
  end

  return axisDetector
end

--removes an axis detector
function tactile.removeAxisDetector(name)
  assert(name, 'name is nil')

  tactile.axisDetectors[name] = nil
end

--holds axis detectors
function tactile.addAxis(detectors)
  assert(type(detectors) == 'table', 'detectors is not a table')

  local axis = {}
  axis.detectors = detectors

  function axis:update()
    axis.value = 0

    --set the overall value to the last non-zero axis detector value
    for i = 1, #self.detectors do
      if self.detectors[i]:getValue() ~= 0 then
        self.value = self.detectors[i]:getValue()
      end
    end
  end

  table.insert(tactile.axes, axis)
  return axis
end

--removes an axis
function tactile.removeAxis(name)
  assert(name, 'name is nil')

  tactile.axes[name] = nil
end

function tactile.update()
  --update button detectors
  for k, v in pairs(tactile.buttonDetectors) do
    v:update()
  end

  --update axis detectors
  for k, v in pairs(tactile.axisDetectors) do
    v:update()
  end

  --update buttons
  for k, v in pairs(tactile.buttons) do
    v:update()
  end

  --update axes
  for k, v in pairs(tactile.axes) do
    v:update()
  end
end

--access functions
function tactile.isDown(button)
  assert(button, 'button is nil')
  return tactile.buttons[button].down
end

function tactile.pressed(button)
  assert(button, 'button is nil')
  return tactile.buttons[button].pressed
end

function tactile.released(button)
  assert(button, 'button is nil')
  return tactile.buttons[button].released
end

function tactile.getAxis(axis)
  assert(axis, 'axis is nil')
  return tactile.axes[axis].value
end

--refreshes the joysticks list
function tactile.getJoysticks()
  tactile.joysticks = love.joystick.getJoysticks()
end

return tactile