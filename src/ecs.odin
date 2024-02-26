package main
import "core:math/linalg"
import "core:mem"
import "raylib"
Vector3 :: raylib.Vector3
Quaternion :: raylib.Quaternion
Transform :: raylib.Transform
// ecs based on https://www.david-colson.com/2020/02/09/making-a-simple-ecs.html

all_components := []typeid {
    Transform,
}

component_id_map: map[typeid]int
world: World

MAX_COMPONENTS :: 32
MAX_ENTITIES :: 1024
EntityID :: distinct u32
EntityIndex :: u16
EntityVersion :: u16
ComponentMask :: bit_set[0..<MAX_COMPONENTS]


EntityDesc :: struct {
    id: EntityID,
    mask: ComponentMask,
}

ComponentPool :: struct {
    elem_size: u32,
    data: rawptr,
}

SceneView :: struct {
    index: uint,
    mask: ComponentMask,
}

World :: struct {
    entities: [dynamic]EntityDesc,
    free_entities: [dynamic]EntityIndex,
    component_pools: [dynamic]ComponentPool,
}

register_components :: proc() {
    if component_id_map != nil {
        delete(component_id_map)
    }
    component_id_map = make(map[typeid]int)
    for tyid, i in all_components {
        component_id_map[tyid] = i + 1
        if len(world.component_pools) <= i {
            append(&world.component_pools, init_component_pool(u32(type_info_of(tyid).size)))
        }
        assert(world.component_pools[i].elem_size == u32(type_info_of(tyid).size))
    }
}

init_ecs :: proc() {
	register_components()
}

free_ecs :: proc() {
    delete(component_id_map)
    for &p in world.component_pools {
        free_component_pool(&p)
    }
    delete(world.entities)
    delete(world.free_entities)
    delete(world.component_pools)
}

// TODO: sparse set the component list into this pool
init_component_pool :: proc(elem_size: u32) -> ComponentPool {
    ptr, err := mem.alloc(int(elem_size * MAX_ENTITIES))
    assert(err == nil)
    return ComponentPool{
        elem_size,
        ptr
    }
}

free_component_pool :: proc(pool: ^ComponentPool) {
    free(pool.data)
}

get_pool_ptr :: proc(pool: ^ComponentPool, index: EntityIndex) -> rawptr {
    return mem.ptr_offset((^rawptr) (pool.data), u32(index) * pool.elem_size)
}

get_component_id :: proc(tyid: typeid, loc := #caller_location) -> int {
    return component_id_map[tyid]
}

get_entity_version :: proc(id: EntityID) -> EntityVersion {
    return EntityVersion(id)
}

get_entity_index :: proc(id: EntityID) -> EntityIndex {
    return EntityIndex(id >> 16)
}

get_entity :: proc(id: EntityID) -> ^EntityDesc {
    assert_valid(id)
    return &world.entities[get_entity_index(id)]
}

create_entity_id :: proc(index: EntityIndex, version: EntityVersion) -> EntityID {
    return EntityID(EntityID(index) << 16 | EntityID(version))
}

create_entity :: proc() -> EntityID {
    if len(world.free_entities) == 0 {
        append(&world.entities, EntityDesc{create_entity_id(EntityIndex(len(world.entities)), 0), ComponentMask{}})
        return world.entities[len(world.entities)-1].id
    } else {
        i := pop(&world.free_entities)
        world.entities[i] = EntityDesc{create_entity_id(EntityIndex(i), 0), ComponentMask{}}
        return world.entities[i].id
    }
}

destroy_entity :: proc(id: EntityID) {
    assert_valid(id)
    i := get_entity_index(id)
    new_id := create_entity_id(0, get_entity_version(id) + 1)
    world.entities[i].id = new_id
    world.entities[i].mask = {}
    append(&world.free_entities, i)
}

is_valid_id :: proc(id: EntityID) -> bool {
    i := get_entity_index(id)
    return i >= 0 && i < EntityIndex(len(world.entities)) && world.entities[i].id == id
}

assert_valid :: proc(id: EntityID, loc := #caller_location) {
    assert(is_valid_id(id), "invalid entity id", loc)
}

make_scene_view :: proc(ts: ..typeid) -> SceneView {
    s := SceneView{}
    for t in ts {
        s.mask += {get_component_id(t)}
    }
    return s
}

iterate_scene_view :: proc(view: ^SceneView) -> (EntityID, bool) {
    for view.index < len(world.entities) {
        if is_valid_id(world.entities[view.index].id) && view.mask == (view.mask & world.entities[view.index].mask) {
            r := world.entities[view.index].id
            view.index += 1
            return r, true
        }
        view.index += 1
    }
    return create_entity_id(0, 0), false
}

add_component :: proc($T: typeid, id: EntityID) -> ^T {
    assert_valid(id)
    c_id := get_component_id(T)
    assert(c_id > 0, "invalid component type")
    // XXX: fmt is broken
    //assert(c_id > 0, fmt.tprint("invalid component type:", typeid_of(T)))
    component_ptr := (^T)(get_pool_ptr(&world.component_pools[c_id-1], get_entity_index(id)))
    component_ptr^ = T{}
    get_entity(id).mask += {c_id}
    return component_ptr
}

get_component :: proc($T: typeid, id: EntityID) -> ^T {
    assert_valid(id)
    comp_id := get_component_id(T)
    assert(comp_id in get_entity(id).mask)
    return (^T)(get_pool_ptr(&world.component_pools[comp_id-1], get_entity_index(id)))
}

get_component_safe :: proc($T: typeid, id: EntityID) -> Maybe(^T) {
    assert_valid(id)
    comp_id := get_component_id(T)
    if comp_id not_in get_entity(id).mask {
        return nil
    } else {
        return get_component(T, id)
    }
}

remove_component :: proc($T: typeid, id: EntityID) {
    component_id := get_component_id(T)
    world.entities[get_entity_index(id)].mask -= {component_id}
}

