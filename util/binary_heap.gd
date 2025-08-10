class_name BinaryHeap
extends RefCounted
# Code from some reddit post, im too lazy to write it
# https://www.reddit.com/r/godot/comments/100vnjv/i_wrote_astar_from_scratch_in_gdscript/
"""
Priority Queue. Min heap priority queue that can take a Vector2 and its
corresponding cost and then always return the Vector2 in it with
the lowest cost value.
Based on: https://en.wikipedia.org/wiki/Binary_heap
"""
var _data: Array[BinHeapElement] = []
var _element_to_index: Dictionary[Variant, int] = {}

class BinHeapElement:
	extends RefCounted
	
	var element: Variant
	var cost: float
	
	func _init(element: Variant, cost: float):
		self.element = element
		self.cost = cost

func insert(element: Variant, cost: float) -> void:
	# Add the element to the bottom level of the heap at the leftmost open space
	self._data.push_back(BinHeapElement.new(element, cost))
	var new_element_index: int = self._data.size() - 1
	self._element_to_index[element] = new_element_index
	self._up_heap(new_element_index)

func lowest_cost() -> Variant:
	if self.is_empty():
		return null
	else:
		return self._data[0].cost

func extract() -> Variant:
	if self.is_empty():
		return null
	var result: BinHeapElement = self._data[0]
	self._element_to_index.erase(result.element)
	# If the tree is not empty, replace the root of the heap with the last
	# element on the last level.
	if not self.is_empty():
		var back_element = self._data.pop_back()
		self._element_to_index[back_element.element] = 0
		self._data[0] = back_element
		self._down_heap(0)
	return result.element

func get_cost(element: Variant) -> Variant:
	if element not in self._element_to_index:
		return null
	
	return self._data[self._element_to_index[element]].cost

func update_cost(element: Variant, new_cost: float) -> void:
	if element not in self._element_to_index:
		return
	
	# update cost of element entry
	var element_index := self._element_to_index[element]
	var element_entry := self._data[element_index]
	var old_cost := element_entry.cost
	element_entry.cost = new_cost
	
	# bubble up or down to reflect new cost
	if new_cost > old_cost:
		self._down_heap(element_index)
	elif new_cost < old_cost:
		self._up_heap(element_index)

func is_empty() -> bool:
	return self._data.is_empty()

func _get_parent(index: int) -> int:
	# warning-ignore:integer_division
	return (index - 1) / 2

func _left_child(index: int) -> int:
	return (2 * index) + 1

func _right_child(index: int) -> int:
	return (2 * index) +  2

func _swap(a_idx: int, b_idx: int) -> void:
	var a := self._data[a_idx]
	var b := self._data[b_idx]
	self._data[a_idx] = b
	self._data[b_idx] = a
	self._element_to_index[a.element] = b_idx
	self._element_to_index[b.element] = a_idx

func _up_heap(index: int) -> void:
	# Compare the added element with its parent; if they are in the correct order, stop.
	var parent_idx = self._get_parent(index)
	if self._data[index].cost >= self._data[parent_idx].cost:
		return
	self._swap(index, parent_idx)
	self._up_heap(parent_idx)

func _down_heap(index: int) -> void:
	var left_idx: int = self._left_child(index)
	var right_idx: int = self._right_child(index)
	var smallest: int = index
	var size: int = self._data.size()

	if right_idx < size and self._data[right_idx].cost < self._data[smallest].cost:
		smallest = right_idx

	if left_idx < size and self._data[left_idx].cost < self._data[smallest].cost:
		smallest = left_idx

	if smallest != index:
		self._swap(index, smallest)
		self._down_heap(smallest)
