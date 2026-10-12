extends Node
func _ready() -> void:
 var harness:=AdvancedCampaignReview.new()
 harness.output="res://qa/advanced_campaign"
 harness.seconds_per_world=0.3
 harness.quit_when_finished=true
 get_tree().root.add_child.call_deferred(harness)
