using UnityEngine;

public class AgentMover : MonoBehaviour
{
    public float speed = 1.5f;

    private CharacterController controller;

    void Start()
    {
        controller = GetComponent<CharacterController>();
    }

    void Update()
    {
        float move = speed * Time.deltaTime;
        Vector3 dir = transform.forward * move;
        controller.Move(dir);
    }
}

