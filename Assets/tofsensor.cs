using UnityEngine;

public class ToFSensor : MonoBehaviour
{
    public float maxDistance = 5f;
    public ExperimentLogger logger;

    private float lastDist = -1f;

    void Start()
    {
        if (logger == null)
        {
            logger = FindObjectOfType<ExperimentLogger>();
        }
    }

    void Update()
    {
        Ray ray = new Ray(transform.position, transform.forward);
        float dist = maxDistance;
        Vector3 hitPoint = transform.position + transform.forward * maxDistance;

        if (Physics.Raycast(ray, out RaycastHit hit, maxDistance))
        {
            dist = hit.distance;
            hitPoint = hit.point;
        }

        // 只有距离变化明显才写一行（避免每帧刷爆）
        if (lastDist < 0 || Mathf.Abs(dist - lastDist) > 0.02f)
        {
            logger.LogSample("tof", dist, hitPoint, transform.position);
            lastDist = dist;
        }

        // 画线：Scene 视图可见
        Debug.DrawRay(ray.origin, ray.direction * dist, Color.red);
    }
}
