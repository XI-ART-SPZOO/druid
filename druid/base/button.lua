local data = require("druid.data")
local ui_animate = require "druid.helper.druid_animate"

local M = {}

M.interest = {
  data.ON_INPUT
}

local BTN_SOUND = "button_click"
local BTN_SOUND_DISABLED = "button_click_disabled"
local HOVER_SCALE = vmath.vector3(-0.025, -0.025, 1)

M.DEFAULT_SCALE_CHANGE = vmath.vector3(-0.05, - 0.1, 1)
M.DEFAULT_POS_CHANGE = vmath.vector3(0, - 10, 0)
M.DEFAULT_MOVE_SPEED = 5
M.DEFAULT_ALPHA_DOWN = 0.8
M.DEFAULT_TIME_ANIM = 0.1
M.DEFAULT_DEACTIVATE_COLOR = vmath.vector4(0, 0, 0, 0)
M.DEFAULT_DEACTIVATE_SCALE = vmath.vector3(0.8, 0.9, 1)
M.DEFAULT_ACTIVATE_SCALE = vmath.vector3(1, 1, 1)
M.DEFAUL_ACTIVATION_TIME = 0.2


function M.init(instance, callback, params, animate_node_name, event)
  instance.event = event or data.A_TOUCH
  instance.anim_node = animate_node_name and gui.get_node(animate_node_name) or instance.node
  instance.scale_from = gui.get_scale(instance.anim_node)
  instance.scale_to = instance.scale_from + M.DEFAULT_SCALE_CHANGE
  instance.scale_hover_to = instance.scale_from + HOVER_SCALE
  instance.pos = gui.get_position(instance.anim_node)
  instance.callback = callback
  instance.params = params
  instance.tap_anim = M.tap_scale_animation
  instance.back_anim = M.back_scale_animation
  instance.hover_anim = true
  -- instance.sound = sound or BTN_SOUND
  -- instance.sound_disable = sound_disable or BTN_SOUND_DISABLED
end

--- Set text to text field
-- @param action_id - input action id
-- @param action - input action
function M.on_input(instance, action_id, action)
  if gui.pick_node(instance.node, action.x, action.y) then
    if action.pressed then
      instance.can_action = true
      instance.repeated_counter = 0
      return true
    end

    if action.released then
      if not instance.disabled then
        if not instance.stub and instance.can_action then
          instance.can_action = false
          instance.tap_anim(instance)
          -- instance.sound()
          instance.callback(instance.parent.parent, instance.params, instance)
        else
          if instance.hover_anim then
            gui.animate(instance.node, "scale", instance.scale_from, gui.EASING_OUTSINE, 0.05)
          end
        end
        return true
      else
        instance.sound_disable()
        return false
      end
    else
      -- scale in
      if instance.hover_anim then
        gui.animate(instance.node, "scale", instance.scale_hover_to, gui.EASING_OUTSINE, 0.05)
      end
    end
    return not instance.disabled
  else
    -- scale back
    -- bad solition, remake with flag
    instance.can_action = false
    if instance.hover_anim then
      gui.animate(instance.node, "scale", instance.scale_from, gui.EASING_OUTSINE, 0.05)
    end
    return false
  end
end

function M.tap_scale_animation(instance)
  ui_animate.scale_to(instance, instance.anim_node, instance.scale_to,
    function()
      if instance.back_anim then
        instance.back_anim(instance)
      end
      -- instance.sound()
    end
  )
end

function M.back_scale_animation(instance)
  ui_animate.scale_to(instance, instance.anim_node, instance.scale_from)
end

function M.tap_tab_animation(instance, force)
  ui_animate.alpha(instance, instance.anim_node, M.DEFAULT_ALPHA_DOWN, nil, M.DEFAULT_TIME_ANIM)
  ui_animate.fly_to(instance, instance.anim_node, instance.pos + M.DEFAULT_POS_CHANGE, M.DEFAULT_MOVE_SPEED)
  ui_animate.scale_to(instance, instance.anim_node, instance.scale_to,
    function()
      if instance.back_anim then
        instance.back_anim(instance)
      end
      instance.callback(instance.parent.parent, instance.params, force)
    end
  )
end

function M.back_tab_animation(instance)
  ui_animate.alpha(instance, instance.anim_node, 1, nil, M.DEFAULT_TIME_ANIM)
  ui_animate.fly_to(instance, instance.anim_node, instance.pos, M.DEFAULT_MOVE_SPEED)
  ui_animate.scale_to(instance, instance.anim_node, instance.scale_from)
end

function M.deactivate(instance, is_animate, callback)
  instance.disabled = true
  if is_animate then
    local counter = 0
    local clbk = function()
      counter = counter + 1
      if counter == 3 and callback then
        callback(instance.parent.parent)
      end
    end
    ui_animate.color(instance, instance.node, M.DEFAULT_DEACTIVATE_COLOR, clbk, M.DEFAUL_ACTIVATION_TIME, 0,
    gui.EASING_OUTBOUNCE)
    ui_animate.scale_y_from_to(instance, instance.node, M.DEFAULT_ACTIVATE_SCALE.x, M.DEFAULT_DEACTIVATE_SCALE.x, clbk,
    M.DEFAUL_ACTIVATION_TIME, gui.EASING_OUTBOUNCE)
    ui_animate.scale_x_from_to(instance, instance.node, M.DEFAULT_ACTIVATE_SCALE.y, M.DEFAULT_DEACTIVATE_SCALE.y, clbk,
    M.DEFAUL_ACTIVATION_TIME, gui.EASING_OUTBOUNCE)
  else
    gui.set_color(instance.node, M.DEFAULT_DEACTIVATE_COLOR)
    gui.set_scale(instance.node, M.DEFAULT_DEACTIVATE_SCALE)
    if callback then
      callback(instance.parent.parent)
    end
  end
end

function M.activate(instance, is_animate, callback)
  if is_animate then
    local counter = 0
    local clbk = function()
      counter = counter + 1
      if counter == 3 then
        instance.disabled = false
        if callback then
          callback(instance.parent.parent)
        end
      end
    end
    ui_animate.color(instance, instance.node, ui_animate.TINT_SHOW, clbk, M.DEFAUL_ACTIVATION_TIME, 0,
    gui.EASING_OUTBOUNCE)
    ui_animate.scale_y_from_to(instance, instance.node, M.DEFAULT_DEACTIVATE_SCALE.x, M.DEFAULT_ACTIVATE_SCALE.x, clbk,
    M.DEFAUL_ACTIVATION_TIME, gui.EASING_OUTBOUNCE)
    ui_animate.scale_x_from_to(instance, instance.node, M.DEFAULT_DEACTIVATE_SCALE.y, M.DEFAULT_ACTIVATE_SCALE.y, clbk,
    M.DEFAUL_ACTIVATION_TIME, gui.EASING_OUTBOUNCE)
  else
    gui.set_color(instance.node, ui_animate.TINT_SHOW)
    gui.set_scale(instance.node, M.DEFAULT_ACTIVATE_SCALE)
    instance.disabled = false
    if callback then
      callback(instance.parent.parent)
    end
  end
end

return M
