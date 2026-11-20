-- All model part references in one place.

local root = models.model.root

return {
    root = root,
    head = root.Head,
    leftEar = root.Head.LeftEar,
    rightEar = root.Head.RightEar,
    tail = root.Tail.Actual,
    tailTarget = root.Tail.Target,
    mouthItem = root.Head.MouthIPivot,
    mouthTool = root.Head.MouthTPivot,
    mouthDrink = root.Head.MouthDPivot,
    leftItemPivot = root.LeftArm.LeftItemPivot,
    rightItemPivot = root.RightArm.RightItemPivot,
    leftArm = root.LeftArm,
    rightArm = root.RightArm,
    leftCalf = root.LeftLeg.LeftCalf,
    rightCalf = root.RightLeg.RightCalf,
}
